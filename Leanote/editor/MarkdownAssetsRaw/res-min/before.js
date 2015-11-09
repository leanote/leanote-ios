function tapLea (parent, child, fn) {
    var collection = this,
        isTouch = "ontouchend" in document.createElement("div"),
        tstart = isTouch ? "touchstart" : "mousedown",
        tmove = isTouch ? "touchmove" : "mousemove",
        tend = isTouch ? "touchend" : "mouseup",
        tcancel = isTouch ? "touchcancel" : "mouseout";
    (function(){
        var i = {};
        $(parent).on(tstart, child, function(e){
            var p = "touches" in e ? e.touches[0] : (isTouch ? window.event.touches[0] : window.event);
            i.startX = p.clientX;
            i.startY = p.clientY;
            i.endX = p.clientX;
            i.endY = p.clientY;
            i.startTime = + new Date;
        });
        $(parent).on(tmove, child, function(e){
            var p = "touches" in e ? e.touches[0] : (isTouch ? window.event.touches[0] : window.event);
            i.endX = p.clientX;
            i.endY = p.clientY;
        });
        $(parent).on(tend, child, function(e) {
            if((+ new Date)-i.startTime<300) {
                if(Math.abs(i.endX-i.startX)+Math.abs(i.endY-i.startY)<20){
                    var e = e || window.event;
                    // e.preventDefault();
                    // console.log(i);
                    fn.call(this, e);
                }
            }
            i.startTime = undefined;
            i.startX = undefined;
            i.startY = undefined;
            i.endX = undefined;
            i.endY = undefined;
        });
    })();
}

function callObjc(url) {
    var iframe = document.createElement("IFRAME");
  iframe.setAttribute("src", url);
  iframe.style.cssText = "border: 0px transparent;";
  document.documentElement.appendChild(iframe);
  iframe.parentNode.removeChild(iframe);
  iframe = null;
}

log = function(o) {
  console.log(o);
  callObjc('callback-log:msg=' + o);
}


var keyboardHeight = 0;
var windowHeight = 0;

var $title = $('#title');
var $content = $('#wmd-input-sub');

// 第三方ios输入法没有keydown事件
var hasKeyDownEvent = false;

$(function() {
    $content.focus(function() {
      log('content focus');
      // console.trace('content focus');
        callObjc('callback-focus-in:id=zss_field_content');
    });
    $content.blur(function() {
    log('content blur');
        callObjc('callback-focus-out:id=zss_field_content');
    });

  // 为了增加可视范围
  $content.on('keydown', function() {
    hasKeyDownEvent = true;
    // callObjc('callback-input:id=zss_field_content');
    callObjc('callback-input:id=zss_field_content~yOffset=' + ZSSEditor.getCaretYPosition());
  });
  $content.on('input', function() {
    if(hasKeyDownEvent) {
      return;
    }
    callObjc('callback-input:id=zss_field_content~yOffset=' + ZSSEditor.getCaretYPosition());
  });

  $title.on('keydown', function(e) {
    hasKeyDownEvent = true;
    var wasEnterPressed = (e.keyCode == '13');
    log('keyCode: ' + e.keyCode);
    if(wasEnterPressed) {
      e.preventDefault();
    }
  });

  // title不允许回车, 回车后, 跳到content
  $title.on('input', function(e) {
    var value = $title.html();
    log('input...' + value);
    var hasDiv = value.indexOf('<div>') !== -1;
    if(hasDiv) {
      value = $title.text();
      $title.text(value);
      $content.focus();
      return false;
    } else {
      // log('一样的' + trimedValue);
    }
  });

    $title.focus(function(e) {
        callObjc('callback-focus-in:id=zss_field_title');
    console.trace('title focus');
    // alert('content focus' + $('#title').attr('contenteditable'));
    });
    $title.blur(function() {
        callObjc('callback-focus-out:id=zss_field_title');
    });

    // 初始化
    callObjc('callback-new-field:id=zss_field_title');
    callObjc('callback-new-field:id=zss_field_content');
  // setTimeout(function() {
    callObjc('callback-dom-loaded:');
  // }, 1000);

  $();
});

var UrlPrefix = "life";
var MD = null;
function log(o) {
    console.log(o);
}
// Use ?debug to serve original JavaScript files instead of minified
window.baseDir = 'res-min';
var isDebug = false;
var isDebugIPad = false;
if (/debug/.test(location)) {
  isDebug = true;
}
if (/ipad/.test(location)) {
  isDebugIPad = true;
}
window.require = {
    baseUrl: window.baseDir,
    // deps: ['main']
};
