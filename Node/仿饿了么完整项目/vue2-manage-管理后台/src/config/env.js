/**
 * 配置编译环境和线上环境之间的切换
 * 
 * baseUrl: 域名地址
 * routerMode: 路由模式
 * baseImgPath: 图片存放地址
 * 
 */

 let routerMode = 'hash';

let baseUrl = '//elm.cangdu.org';
let baseImgPath = '//elm.cangdu.org/img/';

// let baseUrl = ''; 
// let baseImgPath;

// if (process.env.NODE_ENV == 'development') {
// 	baseUrl = 'http://127.0.0.1:27017';
//     baseImgPath = 'http://127.0.0.1:27017/img/';
// }else{
// 	baseUrl = '//elm.cangdu.org';
//     baseImgPath = '//elm.cangdu.org/img/';
// }

export {
	baseUrl,
	routerMode,
	baseImgPath
}