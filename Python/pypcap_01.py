#! python
# coding: utf-8

import pcap
import socket
import struct
import ctypes
import datetime
import threading
import inspect
import traceback
from optparse import OptionParser
from subprocess import *
import sys,os
import time

#根据ip段分析内外网流量数据，我自定义一个函数用来解析子网掩码方式的ip段，这里支持多个ip段，也支持一个段，但是要加‘,’
iplist = '115.12.1.0/24','219.213.232.192/26'  


def _async_raise(tid, exctype):
    if not inspect.isclass(exctype):
        raise TypeError("Only types can be raised (not instances)")
    res = ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, ctypes.py_object(exctype))
    if res == 0:
        raise ValueError("invalid thread id")
    elif res != 1:
        ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, 0)
        raise SystemError("PyThreadState_SetAsyncExc failed")

def ipto(ip,ti):
    d = ti/8
    c = 256/(2**(ti%8))
    ip_items = ip.split('.')
    if len(ip_items[d:]) == 1:
        if ti%8 == 0:
            cmin = '%s.%s' % ('.'.join(ip_items[:d]),'0')
            cmax = '%s.%s' % ('.'.join(ip_items[:d]),'255')
        else:
            for i in range(2**(ti%8)):
	        mymax = (i+1)*c-1
	        mymin=  i*c
	        data =  int(''.join(ip_items[d:]))
	        if data < mymax and data >= mymin:
	            cmin = '%s.%s' % ('.'.join(ip_items[:d]),mymin)
  	            cmax = '%s.%s' % ('.'.join(ip_items[:d]),mymax)
    else:
        if ti%8 == 0:
             cmin = '%s.%s.%s' % ('.'.join(ip_items[:d]),'0',('0.'*(len(ip_items)-d-1))[:-1])
             cmax = '%s.%s.%s' % ('.'.join(ip_items[:d]),'255',('255.'*(len(ip_items)-d-1))[:-1])
        else:
	    for i in range(2**(ti%8)):
                mymax = (i+1)*c-1
                mymin=  i*c
	        data =  int(''.join(ip_items[d]))
	        if data < mymax and data >= mymin:
		    cmin = '%s.%s.%s' % ('.'.join(ip_items[:d]),mymin,('0.'*(len(ip_items)-d-1))[:-1])
		    cmax = '%s.%s.%s' % ('.'.join(ip_items[:d]),mymax,('255.'*(len(ip_items)-d-1))[:-1])
    return cmin,cmax  #返回ip段中可用的最小ip和最大ip


class MYthread(threading.Thread):  #自定义theading.Thread类，能够产生线程并且杀掉线程
    def _get_my_tid(self):
        if not self.isAlive():
            raise threading.ThreadError("the thread is not active")
        if hasattr(self, "_thread_id"):
            return self._thread_id



        for tid, tobj in threading._active.items():
            if tobj is self:
                self._thread_id = tid
                return tid
        raise AssertionError("could not determine the thread's id")
    def raise_exc(self, exctype):
        _async_raise(self._get_my_tid(), exctype)



    def terminate(self):
        self.raise_exc(SystemExit)
class Crawl():  #解析主函数
    def __init__(self,eth,mytime,flag):
        self.bytes = 0
        self.bytes_out = 0
        self.packets = 0
        self.packets_out = 0
        self.eth = eth
        self.mytime = mytime
        self.flag = flag
    def myntohl(self,ip):
        return socket.ntohl(struct.unpack("I",socket.inet_aton(ip))[0])  #inet_aton 将ip地址的4段地址分别进行2进制转化，输出用16进制表示，
                                                     #unpack的处理是按16进制（4bit）将2进制字符，从后向前读入的，低位入
                                                     #ntohl, htonl 表示的是网络地址和主机地址之间的转换（network byte <==> host byte）
                                                     #由于unpack/pack的解/打包的颠倒顺序，必须通过htonl 或者 ntohl 进行处理
                                                     #比如从’192.168.1.235’ 可以转换为数字’3120670912’，此数字为网络字节序
    def check(self,dict,uip):
        flag = 0
        for i in dict.keys():
            if uip > self.myntohl(i) and uip < self.myntohl(dict[i]):  #如果抓取的uip属于ip段，flag＝1，否则为0
#       if (uip > self.myntohl('1941307648') and uip < self.myntohl('1941307903')) or (self.myntohl('3689867456') and uip < self.myntohl('3689867519')):
                 flag =1
        return flag
    def run(self):  #设置的抓取时间里pcap一直抓包，各个队列累加数值，最后除以时间，即平均
        dict = {}
        for i in iplist:
             d = i.split('/')
             cmin,cmax = ipto(d[0],int(d[1]))
             dict[cmin]=cmax  #这里记录一个字典，key是ip段最小的的ip，value是最大的ip



        if self.eth == 'all':
            pc = pcap.pcap()
        else:
            pc = pcap.pcap(self.eth)
        for ptime,pdata in pc:
            #try:
            #    ip_type = socket.ntohs(struct.unpack("H",pdata[12:14])[0])  #
            #except:
            #     pass 
      	    #if ip_type != 2048: 
	    #    continue
 	    s_uip = socket.ntohl(struct.unpack("I",pdata[14+12:14+16])[0]) #源ip的网络字节序
	    #d_uip = socket.ntohl(struct.unpack("I",pdata[14+16:14+20])[0])  #目的ip的网络字节序
            bytes = socket.ntohs(struct.unpack("H",pdata[14+2:14+4])[0])+14 #数据的字节数
            if self.check(dict,s_uip):
	        self.bytes_out += bytes
                self.packets_out += 1
 	    else:
	        self.bytes += bytes
                self.packets += 1
    def withtime(self):
        pid =  os.getpid()
        name = sys.argv[0]
        Popen("kill -9 `ps -ef |grep %s|grep -v grep |awk '{print $2}'|grep -v %d`" % (name,pid),stdout=PIPE, stderr=PIPE,shell=True) #这里是
                                     #在启动时候主动杀掉系统中存在的残留程序,使用中发现有时候（极少）执行时间到没有杀掉程序，为了定时任务安全
        self.t = MYthread(target = self.run)
        self.t.setDaemon(1)
        self.t.start()
        curtime = time.ctime(time.time())
        t = 0
        while t<int(self.mytime):
           t +=1
           time.sleep(1)
        nowtime = time.ctime(time.time())
        data = "From[%s]To[%s]%s\n%s%s%s%s\n%s%s%s%s\n" \
        % (curtime,nowtime,u'数据统计'.encode('utf8'),u'出网总流量/s'.encode('utf8').ljust(22,' '),\
           u'出网总数据包/s'.encode('utf8').ljust(22,' '),u'进网总流量/s'.encode('utf8').ljust(22,' '),\
           u'进网总数据包/s'.encode('utf8').ljust(22,' '),str(int(self.bytes_out)/int(self.mytime)).ljust(18,' '),\
           str(int(self.packets_out)/int(self.mytime)).ljust(18,' '),str(int(self.bytes)/int(self.mytime)).ljust(18,' '),\
           str(int(self.packets)/int(self.mytime)).ljust(18,' '))
        if self.flag:
            print data
        self.log(data)
        self.t.terminate()
        self.t.join()



    def log(self,log):  #记录日志，使用－p选项只在记录，不在终端打印，用于定时任务等需求时（定时任务执行没必要输出）
        path = os.path.split(os.path.realpath(__file__))[0]
        log_file = "%s/common.log" % path
        if not os.path.exists(log_file):
            f=open(log_file,'w')
            f.close()
        try:
            fr = open(log_file, "a+")
            fr.write(log+"\r\n")
	    fr.close()
	except Exception, e:
            pass



if __name__ == '__main__':
    argc = len(sys.argv)
    parser = OptionParser(description="Use For Capture and Analysis packets",add_help_option=False,prog="sniffer.py",usage="%prog [ -e <ethname>][ -t <time>]")
    parser.add_option("-e", "--eth",action = "store",default = "all",help = "Select the card, the default is 'all'") #选择网卡，默认是all
    parser.add_option("-t", "--time",action = "store",default = 5,help = "Select the capture time,the default is 5s")  #设置要抓包的时间，单位秒，时间越长越精确
    parser.add_option("-p", "--myprint",action = "store_false",default = True,help = "Print data, the default is true")
    parser.add_option("-h", "--help",action = "help",help="print help")
    options, arguments=parser.parse_args()
    a = Crawl(options.eth,options.time,options.myprint)
    a.withtime()


print('123')
