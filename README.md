# Promise
### 什么是Promise？

所谓Promise，就是一个对象，是异步编程的一种解决方案，用来传递异步操作的消息。它有三种状态，分别是pending-进行中、resolved-已完成、rejected-已失败。Javascript是没办法阻塞的，所有的等待只能通过回调来完成，这就造成了，回调嵌套的问题，代码一层套一层完全没法看，完全没有语意效果，后期维护起来头大，所以Promise的方式更简洁，优势更明显。
	
	当Promise的状态由pending转变为resolved或rejected时，会执行相应的方法，并且状态一旦改变，就无法再次改变状态，这也是它名字promise-承诺的由来。
	
缺点：首先，无法取消Promise，一旦新建它就会立即执行，无法中途取消。其次，如果 不设置回调函数，Promise内部抛出的错误，不会反应到外部。第三，当处于Pending状态时，无法得知目前进展到哪一个阶段(刚刚开始还是即将完成)。

###基本用法

初始化可以有两种方式：

	// 方法1------箭头函数方式赋值
	let promise = new Promise ( (resolve, reject) => {
	    if ( success ) {
	        resolve(a) // pending ——> resolved 参数将传递给对应的回调方法
	    } else {
	        reject(err) // pending ——> rejectd
	    }
	} )
	

	// 方法2------正常函数返回一个对象方式
	function promise () {
	    return new Promise ( function (resolve, reject) {
	        if ( success ) {
	            resolve(a)
	        } else {
	            reject(err)
	        }
	    } )
	}
	
###then和catch的用法

这两个都是链式使用的，都是处理promise状态更改后的回调函数，也有返回值，返回的也是一个promise对象（这个对象的抛错具有冒泡性质，不断传递），不一样的只是then可以接受两个参数，第一个是resolve，第二个是reject，正常来说，捕获error不要用then的第二个参数，因为这个只能捕获指定的promise中的error，而使用catch来捕获则可以捕获包括then里面的error，同时也可以在后面继续写一个catch来捕获catch（）里面的error。另外，使用rejects()方法改变状态和抛出错误 throw new Error() 的作用是相同的。

	// 两个参数的方式
	promise.then(
    () => { console.log('this is success callback') },
    () => { console.log('this is fail callback') })
    
    // catch方式捕获
    promise.then(
    () => { console.log('this is success callback') }
	).catch(
    (err) => { console.log(err) })
    

我们看一个例子：

```
	var p1 = new Promise(function(resolve,reject){
    setTimeout(()=>reject(new Error('fail')),3000);
    });

	var p2 = new Promise(function(resolve,reject){
	    setTimeout(()=>resolve(p1),1000);
	});

	p2.then(result =>console.log(result))
  .catch(error =>console.log(error))
```
这里一个异步操作的结果（p1）是另一个异步操作（p2的操作），也就是在p1状态没改变之前，p2是不会改变的，依赖于p1的状态，但不代表p2的状态就会失效。
###扩展 Promise.all() &  Promise.race()
promise.all()可以理解为与或非这种逻辑用法，把所有的promise对象放到里面，当所有状态变成了resolve，则这个总的对象就是resolve，如果有一个是reject，那么这个总得状态就是reject。

Promise.race()这个则不一样，对象池里面的谁的状态最先改变，那么总的状态就依他，可以叫做“竞速方法”。

另外，不管以then方法或catch方法结尾，要是最后一个方法抛出错误，都有可能无法捕捉到（因为Promise内部的错误不会冒泡到全局）。因此，我们可以提供一个done()方法，总是处于回调链的尾端，保证抛出任何可能出现的错误。类似于这个：

	asyncFunc()
    .then(f1)
    .catch(r1)
    .then(f2)
    .done();

最后一个finally()方法用于指定不管Promise对象最后状态如何，都会执行的操作。它与done方法的最大区别，它接受一个普通的回调函数作为参数，该函数不管怎样都必须执行。

可以举个例子，假如一个网络请求的时候会弹出来一朵菊花，无论成功还是失败，只要状态有改变，那么就可以只是这个关闭菊花的回调函数

Promise.try()用法---额外用法
---
	function getUsername(userid){
    return database.users.get({id:userid})
           .then(function(user){
               return user.name
           });
	}
这个的.then能返回一个Promise对象，可以处理异步的结果或者错误，可以加一个catch部或错误，但是这样还不能处理同步的错误，如果要预防同步错误就要用try...catch去捕获，但是Promise方式处理异常就简单很多：

	// 用promise.try()包装一下就可以了
	Promise.try(database.users.get({id:userid}))
       .then(...)
       .catch(...)

###参考

关于ES6 Promise比较权威的规范：http://www.ecma-international.org/ecma-262/6.0/#sec-promise-objects	
阮一峰的es6参考：http://es6.ruanyifeng.com/


###例子

一个Promise对象的状态一经改变，那么这个Promise就执行完毕，不会再更改状态：

	p2 = new Promise(function(resolve,reject){
	// 为了检验方便，可以吧resolve和reject两个函数顺序调换尝试
    resolve('resolve')
	reject('reject')
	});
	
	p2.then(result => {console.log(result); console.log('123')})
	  .catch(error => {console.log(error); console.log('456')})

一个Promise的结果是另一个Promise回调函数的参数：

	p1 = new Promise(function(resolve,reject){
    setTimeout(()=>reject('fail'),3000);
	});
	
	p2 = new Promise(function(resolve,reject){
		console.log('laile')
	    setTimeout(()=> {console.log('hahahaha'); resolve(p1)},4000);
		console.log('youlaile')
	});
	
	p1.catch(result => console.log(result))
	
	p2.then(result => {console.log(result); console.log('123')})
	  .catch(error => {console.log(error); console.log('456')})

Promise.all()的例子：

	p1 = new Promise(function(resolve,reject){
		resolve('resolve')
		
	});
	p2 = new Promise(function(resolve,reject){
		reject('reject')
		
	});
	p3 = new Promise(function(resolve,reject){
		resolve('resolve')
		
	});
	p = Promise.all([p1,p2,p3])
	
	p.then(result => {console.log(result); console.log('123')})
	  .catch(error => {console.log(error); console.log('456')})

Promise.race()的例子：

	p1 = new Promise(function(resolve,reject){
	setTimeout(()=>resolve('first'),2000);
		
	});
	p2 = new Promise(function(resolve,reject){
		setTimeout(()=>reject('second'),1000);
		
	});
	p3 = new Promise(function(resolve,reject){
		setTimeout(()=>resolve('third'),2000);
		
	});
	p = Promise.race([p1,p2,p3])
	p.then(result => {console.log(result); console.log('123')})
  	.catch(error => {console.log(error); console.log('456')})
  	
  	
说明：当promise.all()的情况，如果全是resolve的状态，那么返回的参数里面就是一个数组，promise.race()里面，最快返回的Promise对象就是总的Promise对象属性，如果同时返回，那么只取第一个执行的Promise返回的对象的回调函数里面的值或对象。
  	
  	
###用处，场景

也就是用来把对象链式串起来用，还有异步回调可以使用

