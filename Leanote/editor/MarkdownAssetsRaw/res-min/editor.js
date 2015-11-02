
var MDInited = false;

function setEditorContent(content) {
  if(MD && content) {
    MD.setContent(content);
    MDInited = true;
  } else {
    clearIntervalForSetContent = setTimeout(function() {
      setEditorContent(content, true);
    }, 100);
  }
}
// 初始化MD
// setEditorContent("");

function ZSSField(wrappedObject, isTitle) {
  this.wrappedObject = wrappedObject;
  this.isTitle = isTitle;
  this.bodyPlaceholderColor = '#000000';
}

ZSSField.prototype.enableEditing = function() {
  if(this.isTitle) {
    this.wrappedObject.attr('contenteditable', true);
  }
  else {
    LEAMD.toggleWrite();
  }
}
ZSSField.prototype.disableEditing = function () {
    if(this.isTitle) {
      this.blur();
      this.wrappedObject.attr('contenteditable', false);
    }
    else {
      LEAMD.togglePreview();
    }
};

ZSSField.prototype.setHTML = function(html) {
  if(this.isTitle) {
    this.wrappedObject.html(html);
  }
  else {
    setEditorContent(html);
  }
},

ZSSField.prototype.setPlainText = function(html) {
    this.wrappedObject.text(html);
},
ZSSField.prototype.strippedHTML = function() {
    return this.wrappedObject.text();
},
ZSSField.prototype.getHTML = function() {
    if(this.isTitle) {
      return this.wrappedObject.html();
    }
    else {
      if(MD) {
        return MD.getContent();
      }
      return "";
    }
}

ZSSField.prototype.isFocused = function() {
    return this.wrappedObject.is(':focus');
};

// 找到原因了, 为什么restoreRange22前会有focus?
ZSSField.prototype.focus = function() {
    if (!this.isFocused()) {
        this.wrappedObject.focus();
    }
};

ZSSField.prototype.blur = function() {
    if (this.isFocused()) {
        this.wrappedObject.blur();
    }
};

ZSSField.prototype.hasPlaceholderText = function() {
    return this.wrappedObject.attr('placeholderText') != null;
};

ZSSField.prototype.setPlaceholderText = function(placeholder) {
    this.wrappedObject.attr('placeholderText', placeholder);
};

ZSSField.prototype.setPlaceholderColor = function(color) {
    this.bodyPlaceholderColor = color;
    this.refreshPlaceholderColor();
};

ZSSField.prototype.refreshPlaceholderColor = function() {
     this.refreshPlaceholderColorForAttributes(this.hasPlaceholderText(),
                                               this.isFocused(),
                                               this.isEmpty());
};

ZSSField.prototype.refreshPlaceholderColorAboutToGainFocus = function(willGainFocus) {
    this.refreshPlaceholderColorForAttributes(this.hasPlaceholderText(),
                                              willGainFocus,
                                              this.isEmpty());
};

ZSSField.prototype.refreshPlaceholderColorForAttributes = function(hasPlaceholderText, isFocused, isEmpty) {
    
    var shouldColorText = hasPlaceholderText && isEmpty;
    
    if (shouldColorText) {
        if (isFocused) {
            this.wrappedObject.css('color', this.bodyPlaceholderColor);
        } else {
            this.wrappedObject.css('color', this.bodyPlaceholderColor);
        }
    } else {
        this.wrappedObject.css('color', '');
    }
    
};

var titleField = new ZSSField($($title), true);
var contentField = new ZSSField($content);

// 整体API
var LEAMD = {
  mdEditorO: $('#mdEditor'),

  // 绑定事件
  init: function() {

    this.isiPad = (navigator.userAgent.match(/iPad/i) != null);
    if (this.isiPad) {
        $(document.body).addClass('ipad_body');
    }
    
    // tap事件
    tapLea('#preview-contents', 'img, a', function() {
      if($(this).is('img')) {
        var src = $(this).attr('src');
        if(!src) {
          return;
        }

        // 所有image
        var allImages = [];
        $('#preview-contents img').each(function() {
          var url = $(this).attr('src')
          if(url) {
            allImages.push(url);
          }
        });

        allImages.push(src);
        callObjc('callback-image-tap:id=0~url=' + allImages.join(',')); //  + '~meta='
      }
      else {
        var href = $(this).attr('href');
        callObjc('callback-link-tap:id=zss_field_content~url=' + href);
      }
    });

    /*
    $('#preview-contents').on('click', 'img, a', function() {
      if($(this).is('img')) {
        var src = $(this).attr('src');
        callObjc('callback-image-tap:id=0~url=' + src); //  + '~meta='
      }
      else {
        var href = $(this).attr('href');
        callObjc('callback-link-tap:id=zss_field_content~url=' + href);
      }
    });
    */

  },

  togglePreview: function() {
    // blur会隐藏keyboard, 也会隐藏按钮, TODO
    // $('#title').blur();
    $content.blur();
    $content.attr('contenteditable', false);
    $title.attr('contenteditable', false);
    this.mdEditorO.removeClass('write');
    // 到最前面
    $('body').scrollTop(0);
  },
  toggleWrite: function() {
    // alert('toggleWrite haha');
    this.mdEditorO.addClass('write');
    $content.attr('contenteditable', true);
    $title.attr('contenteditable', true);
    if (!MDInited) {
      // setEditorContent("");
    }
    // if(!titleField.strippedHTML()) {
    setTimeout(function() {
      $title.focus();
    })
    // }
    // else {
      // $content.focus();
    // }
  },
  keyboardShow: function(height, _windowHeight) {
    window.keyboardHeight = height;
    window.windowHeight = _windowHeight;
    // this.restoreRange();
    // $('#tools').css('bottom', height);
    // $('#wmd-input').scrollTop(pos - 64);
    // $('#note').css('bottom', height);
    // $('#wmd-input').scrollTop($('#wmd-input').scrollTop() + height);
  },

  lastTime:11,
  lastTop:0,
  keyboardHide: function() {
    // MD.selectionMgr.updateCursorCoordinates(true);
    
    /*
    // this.restoreRange();
    var top;
    console.log(top);
    var now = (new Date()).getTime();
    var i = (now - this.lastTime) / 1000;
    if(i > 1) {
      top = $('body').scrollTop();
    } else {
      top = this.lastTop;
    }
    setTimeout(function() {
      $('body').scrollTop(top);
    }, 200);
    this.lastTime = now;
    this.lastTop = top;
    */
  },

  // API调用
  // ZSSEditor.insertLocalImage(\"%@\", \"%@\");
  insertLocalImage: function(id, url) {
    MD.insertLink(url, "", true);
  },
  insertImage: function(urls, alt) {
    MD.insertLink(urls, alt, true);
  },
  insertLink: function(url, title) {
    MD.insertLink(url, title, false);
  },
  setBold: function() {
    MD.execCommand('bold');
  },
  setItalic: function() {
    MD.execCommand('italic');
  },
  setHorizontalRule: function() {
    MD.execCommand('hr');
  },
  setHeading: function() {
    MD.execCommand('heading');
  },
  setBlockquote: function() {
    MD.execCommand('blockquote');
  },
  setUnorderedList: function() {
    MD.execCommand('list');
  },
  setOrderedList: function() {
    MD.execCommand('numberList');
  },

  getField: function(field) {
    if(field === 'zss_field_title') {
      return titleField;
    }
    return contentField;
  },

  // 为了第三方键盘恶心!
  newline: function() {
    MD.selectionMgr.saveSelectionState();
    $('.editor-content').trigger('newline');
  },

  /*
  键盘显示, handleInputCallback, handleSelectionCallback 都会调用, 滚动到caret, 这是由objc来控制的
  - (void)scrollToCaretAnimated:(BOOL)animated
  */

  // 备份range, 链接添加之前, textColor, bgColor
  _range: {},
  backupRange: function() {
    log('backupRange11');
    MD.selectionMgr.saveSelectionState();
    // this._range = MD.selectionMgr.getCoordinates(MD.selectionMgr.selectionEnd, MD.selectionMgr.selectionEndContainer, MD.selectionMgr.selectionEndOffset);
  },

  // restore之
  // 图片插入后, 取消, 取消链接都会执行这个
  // 会focus输入框
  restoreRange: function() {
    // log(this._range.y);
    // $('#wmd-input-sub').focus();
    
    // return;

    log('restoreRange22');
    MD.execCommand('blank');

    // MD.execCommand('blank');已调用
    // MD.selectionMgr.updateCursorCoordinates(true);

    // if(this._range) {
      // $('body').scrollTop(this._range.y - 90);
    // }
  }
  
};

LEAMD.init();
var ZSSEditor = LEAMD;

ZSSEditor.refreshVisibleViewportSize = function() {
  /*
    $(document.body).css('min-height', window.innerHeight + 'px');
    $('#mdEditor').css('min-height', (window.innerHeight - $('#mdEditor').position().top) + 'px');
  */
};

ZSSEditor.closerParentNodeWithName = function(nodeName) {
    
    var parentNode = null;
    var selection = window.getSelection();
    var range = selection.getRangeAt(0).cloneRange();
    
    var referenceNode = range.commonAncestorContainer;
    
    return this.closerParentNodeWithNameRelativeToNode(nodeName, referenceNode);
};

ZSSEditor.closerParentNodeWithNameRelativeToNode = function(nodeName, referenceNode) {
    
    nodeName = nodeName.toUpperCase();
    
    var parentNode = null;
    var currentNode = referenceNode;
    
    while (currentNode) {
        
        if (currentNode.nodeName == document.body.nodeName) {
            break;
        }
        
        if (currentNode.nodeName == nodeName
            && currentNode.nodeType == document.ELEMENT_NODE) {
            parentNode = currentNode;
            
            break;
        }
        
        currentNode = currentNode.parentElement;
    }
    
    return parentNode;
};
ZSSEditor.closerParentNode = function() {
    var parentNode = null;
    var selection = window.getSelection();
    var range = selection.getRangeAt(0).cloneRange();
    
    var currentNode = range.commonAncestorContainer;
    
    while (currentNode) {
        if (currentNode.nodeType == document.ELEMENT_NODE) {
            parentNode = currentNode;
            
            break;
        }
        
        currentNode = currentNode.parentElement;
    }
    return parentNode;
};

ZSSEditor._getCaretYPosition = function() {
  // console.trace('_getCaretYPosition');
    // 这个有问题, 不能这样, 不然cursor有问题
    var selection = window.getSelection();
    var range = selection.getRangeAt(0);
    var span = document.createElement("span");
    // Ensure span has dimensions and position by
    // adding a zero-width space character
    span.appendChild( document.createTextNode("\u200b") );
    range.insertNode(span);
    var y = span.offsetTop;
    var spanParent = span.parentNode;
    spanParent.removeChild(span);
    
    // Glue any broken text nodes back together
    spanParent.normalize();
    return y;
}

ZSSEditor.getCaretYPosition = function() {
    var selection = window.getSelection();
    var noSelectionAvailable = selection.rangeCount == 0;
    
    if (noSelectionAvailable) {
        return null;
    }
    
    var y = 0;
    var height = 0;
    var range = selection.getRangeAt(0);
    var needsToWorkAroundNewlineBug = (range.getClientRects().length == 0);
    
    // PROBLEM: iOS seems to have problems getting the offset for some empty nodes and return
    // 0 (zero) as the selection range top offset.
    //
    // WORKAROUND: To fix this problem we use a different method to obtain the Y position instead.
    //
    if (needsToWorkAroundNewlineBug) {
        var closerParentNode = ZSSEditor.closerParentNode();
        var closerDiv = ZSSEditor.closerParentNodeWithName('div');
        
        var fontSize = $(closerParentNode).css('font-size');
        var lineHeight = Math.floor(parseInt(fontSize.replace('px','')) * 1.5);
        
        y = this._getCaretYPosition();
        height = lineHeight;
    } else {
        if (range.getClientRects) {
            var rects = range.getClientRects();
            if (rects.length > 0) {
                // PROBLEM: some iOS versions differ in what is returned by getClientRects()
                // Some versions return the offset from the page's top, some other return the
                // offset from the visible viewport's top.
                //
                // WORKAROUND: see if the offset of the body's top is ever negative.  If it is
                // then it means that the offset we have is relative to the body's top, and we
                // should add the scroll offset.
                //
                var addsScrollOffset = document.body.getClientRects()[0].top < 0;
                
                if (addsScrollOffset) {
                    y = document.body.scrollTop;
                }
                
                y += rects[0].top;
                height = rects[0].height;
            }
        }
    }
    
    // this.caretInfo.y = y;
    // this.caretInfo.height = height;
    log('getCaretYPosition: ' + y);
    return y;

    return {y: y, height: height};
};

ZSSEditor.getSelectedText = function() {
  var selection = window.getSelection();
  if(selection) {
    return selection.toString();
  }
  return '';
};

ZSSEditor.logMainElementSizes = function() {};

// life test
if(isDebug) {
  titleField.enableEditing();
  contentField.enableEditing();
  var content = $('#life').val();
  setEditorContent(content);
}
