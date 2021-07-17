/* global tinymce */

/**
 * The input contains invalid characters. All alphanumeric characters, 
 * plus these non alphanumeric chars: /.?&+:-@ and spaces are allowed.
 */
if (_ZENTYAL_UTIL_init === undefined) {

    let create_ZENTYAL_UTIL = function () {
      var _ZENTYAL_UTIL = {
          config: {
              //field: 'td',
              field: '.init-span',
              hint: '.html-editor'
          },
          container: null,
          get_container: function () {
            // return jQuery(".zentyal-util-base-container");  
            if (this.container) {
              return this.container
            }

            throw Error('no container')
          },
          get_input: function () {
              var _ = this;
              var _field = _.get_container();
              var _input = _field.find('input:first');
              if (_input.length === 0) {
                  _input = _field.parents("div:first").find('input:first');
              }
              return _input;
          },
          set_input: function (_content) {
              var _content = this.encode(_content);
              this.get_input().val(_content);
          },
          set_view: function (_content) {
              this.get_container().find(".html-editor-view").html(_content);
          },
          inited: false,
          init: function(id) {
              var _ = this;

              if (this.inited === true) {
                return false
              }
              this.inited = true

              console.log('到底是錯在哪裡？', id)

              // 測試用
              //var _content = "+003C+0070+003E+6A21+64EC+5A18+5A18+5EDF+6A21+64EC+5EAB+6A21+584A+003C+002F+0070+003E";
              //console.log(["_content", _.decode(_content)]);

              this.load_jquery(function() {
                  //console.log("jquery 讀取完畢");
                  //var _trigger = jQuery(".init-button.trigger");
                  var _trigger
                  if (id) {
                    _trigger = jQuery("#" + id + '_InitButton');
                  }
                  else {
                    _trigger = jQuery(".init-button.trigger");
                  }
                  var _container = _trigger.parents(_.config.field + ":first").parent();
                  _container.addClass('zentyal-util-base-container')
                  _.container = _container
                  //console.log(["_container.length", _container.length]);

                  let editor
                  if (id) {
                    editor = jQuery("#" + id + '_HTMLEditor')
                  }
                  else {
                    editor = jQuery(".html-editor")
                  }

                  editor.css("color", "black")
                      .hide();

                  // 移除文字節點
                  var _input = _.get_input();
                  _input.parent().contents().filter(function() {
                      return (this.nodeType === 3);
                  }).remove();


                  // 把view放進去
                  var _view = jQuery('<div class="html-editor-view" style=""></div>');
                  _view.attr("style", "position: relative;background-color: #fff;box-shadow: 0 0 0 1px rgba(39,41,43,.15),0 1px 2px 0 rgba(0,0,0,.05);padding: 1em;border-radius: .2857rem;border: none;");
                  editor.prepend(_view);

                  _.load_tinymce(function() {
                      //console.log("tinymce 讀取完畢");
                      var _after_init = function () {

                          //console.log(['jQuery(".init-button").length', jQuery(".init-button").length]);
                          //alert([_trigger.length, _trigger.parents(_.config.field + ":first").length, _trigger.parents(_.config.field + ":first").find("button.edit").length]);


                          //var _edit_button = _.get_container().find("button.edit");
                          //console.log(['_edit_button.length', _edit_button.length]);

                          _trigger.remove();

                          let initSpan
                          if (id) {
                            initSpan = jQuery('#' + id + '_InitSpan')
                          }
                          else {
                            initSpan = jQuery(".init-span")
                          }

                          initSpan.remove();

                          //_edit_button.click();

                          //jQuery(window).resize(function() {
                              //console.log('resized');
                              //_.resize_overlay();
                          //});



                          //setTimeout(function () {
                          jQuery(".html-editor.inited").show();
                          //}, 500);
                      };

                      _.main(_after_init);

                      //setTimeout(_after_init, 100);

                      /*
                      setTimeout(function () {
                          var _trigger = jQuery(".init-button.trigger");
                          //alert([jQuery(".init-button").length]);
                          //alert([_trigger.length, _trigger.parents(_.config.field + ":first").length, _trigger.parents(_.config.field + ":first").find("button.edit").length]);
                          var _edit_button = _trigger.parents(_.config.field + ":first").find("button.edit");

                          jQuery(".init-button").remove();

                          _edit_button.click();
                      }, 100);
                      */
                  });
              });
          },
          main: function(_callback) {
              var _ = this;
              var _selector = '.html-editor:not(.inited)';

              //console.log(['selector legnth', jQuery(_selector).length]);

              jQuery(_selector).each(function(_i, _hint) {
                  _hint = jQuery(_hint);

                  //_hint.css("border", "3px solid red");

                  var _textarea = _.create_overlay();
                  _hint.append(_textarea);
                  //_hint.append('<div class="view"></div>');

                  var _btn = _.create_toggle_button();
                  _hint.prepend(_btn);

                  //var _field_container = _hint.parents(_.config.field + ':first');
                  var _field_container = _.get_container();

                  //alert(_field_container.contents().length);
                  _field_container.contents().eq(2).remove();

                  //var _input = _field_container.find('input:first');
                  var _input = _.get_input();
                  _input.hide();

                  //var _view = _field_container.find('.html-editor .html-editor-view');
                  //var _str = _input.val();
                  //_str = _.decode(_str);
                  //_view.html(_str);

                  _hint.addClass("inited");
                  _hint.hide();
              });
              //console.log("ready init");
              tinymce.init({
                  selector: 'textarea.html-editor-textarea',
                  //width : "80%",
                  theme: "modern",
                  plugins: [
                      "advlist autolink lists link image charmap hr anchor pagebreak",
                      "searchreplace wordcount visualblocks visualchars code fullscreen",
                      "insertdatetime media nonbreaking save table contextmenu directionality",
                      "template paste textcolor"
                  ],
                  toolbar1: "insertfile undo redo | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent",
                  toolbar2: "link image media | forecolor backcolor",
                  image_advtab: true,
                  init_instance_callback: function (_ed) {

                      // 開啟時要載入參數
                      var _input = _.get_input();
                      var _content = jQuery.trim(_input.val());
                      //console.log(['content', _content]);
                      if (_content !== undefined && _content !== "") {
                          if (_content.length > 1 && _content.substr(0,1) === "+") {
                              _content = _.decode(_content);
                          }
                          //console.log(["content", _content]);
                          _ed.setContent(_content);
                          _.set_view(_content);
                          _.toggle_edit(false);
                      }
                      else {
                          _.toggle_edit(true);
                      }

                      //console.log(['next', _input.length, _input.parent().length
                      //    , _input.parent().contents().filter(function() {
                      //        return (this.nodeType === 3);
                      //    })
                      //]);

                      if (typeof(_callback) === 'function') {
                          _callback();
                      }
                  },
                  setup: function (_ed) {
                      _ed.on('blur', function (_e) {
                          var _content = _ed.getContent();
                          _.set_input(_content);
                          _.set_view(_content);
                          //console.log('Editor contents was modified. Contents: ' + _ed.getContent());
                      });
                  }
              });
          },
          //jquery_url: 'http://pc-pudding.dlll.nccu.edu.tw/zentyal-dlll/dlllciasrouter/javascript/jquery.min.js',    // 不能用HTTP!!
          //jquery_url: 'https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/jquery.min.js',
          //jquery_url: 'http://pc-pudding-2013.dlll.nccu.edu.tw/zentyal-dlll/zentyal-field/jquery.min.js',
          jquery_url: '/data/dlllciasrouter/js/jquery.min.js',
          load_jquery: function(_callback) {
              //alert(typeof (jQuery));
              if (typeof (jQuery) !== 'undefined') {
                  _callback();
                  return;
              }
              var _jquery_url = this.jquery_url;
              var _head = document.getElementsByTagName('body')[0];
              var _script = document.createElement('script');
              _script.type = 'text/javascript';
              _script.src = _jquery_url;
              _script.onreadystatechange = function() {
                  if (typeof (this.readyState) !== 'undefined'
                          && this.readyState === 'complete') {
                      if (typeof (_callback) === 'function') {
                          _callback();
                      }
                  }
              };
              _script.onload = function() {
                  if (typeof (_callback) === 'function') {
                      setTimeout(function() {
                          _callback();
                      }, 0);
                  }
              };

              if (_head !== undefined) {
                  _head.appendChild(_script);
              }
          },
          //tinymce_url: 'https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/tinymce/js/tinymce/tinymce.min.js',
          //tinymce_url: 'http://pc-pudding-2013.dlll.nccu.edu.tw/zentyal-dlll/zentyal-field/tinymce/js/tinymce/tinymce.min.js',
          tinymce_url: '/data/dlllciasrouter/js/tinymce/js/tinymce/tinymce.min.js',
          load_tinymce: function(_callback) {
              //console.log(typeof(tinymce));
              if (typeof(tinymce) !== 'undefined') {
                  _callback();
                  return;
              }
              /*
              var _script = jQuery('<script type="text/javascript" src="' + this.tinymce_url + '"></script>');
              _script.attr('onreadystatechange', function() {
                  if (typeof (this.readyState) !== 'undefined'
                          && this.readyState === 'complete') {
                      if (typeof (_callback) === 'function') {
                          _callback();
                      }
                  }
              });
              _script.attr('onload', function() {
                  if (typeof (_callback) === 'function') {
                      setTimeout(function() {
                          _callback();
                      }, 0);
                  }
              });

              _script.appendTo('body');
              */
              var _jquery_url = this.tinymce_url;
              var _head = document.getElementsByTagName('body')[0];
              var _script = document.createElement('script');
              _script.type = 'text/javascript';
              _script.src = _jquery_url;
              _script.onreadystatechange = function() {
                  if (typeof (this.readyState) !== 'undefined'
                          && this.readyState === 'complete') {
                      if (typeof (_callback) === 'function') {
                          _callback();
                      }
                  }
              };
              _script.onload = function() {
                  if (typeof (_callback) === 'function') {
                      setTimeout(function() {
                          _callback();
                      }, 0);
                  }
              };

              if (_head !== undefined) {
                  _head.appendChild(_script);
              }

          },
          create_overlay: function() {
  //            var _ele = jQuery('<div></div>')
  //                    .addClass('zentyal-field-html-editor')
  //                    .addClass('overlay');
  //
  //            var _background = jQuery('<div />')
  //                    .addClass('background')
  //                    .appendTo(_ele);
  //
  //            var _inner = jQuery('<div></div>')
  //                    .addClass('inner')
  //                    .appendTo(_ele);

              var _editor = '<div class="html-editor-container" style="display:none;"><textarea class="html-editor-textarea"></textarea></div>';
              return _editor;
  //            
  //            _inner.append(_editor);
  //
  //            var _ = this;
  //            var _btn = jQuery('<button type="button" class="close zentyal-field" id="close_zentyal_field"></button>')
  //                    .css("width", "20em")
  //                    .css("height", "3em")
  //                    .css("background-color", "white")
  //                    .html('SAVE & CLOSE')
  //                    .appendTo(_inner)
  //                    .click(function() {
  //                        _.close_overlay(jQuery(this));
  //                    });
  //
  //            _background.css({
  //                'background-color': 'black',
  //                'opacity': '0.7',
  //                'position': 'fixed',
  //                'width': '100%',
  //                'height': "100%",
  //                "padding-top": "30px",
  //                'top': '0px',
  //                'left': '0px'
  //            });
  //
  //            _inner.css({
  //                'width': "80%",
  //                "margin-left": "10%",
  //                "margin-right": "auto",
  //                //'padding': "50px",
  //                'text-align': 'center',
  //                'position': 'fixed',
  //                'top': "10%",
  //                'left': 0
  //                        //'background-color': 'white'
  //            });
  //
  //            _ele.hide();
  //
  //            return _ele;
          },
  //        create_edit_button: function() {
  //            var _ele = jQuery('<button type="button" class="edit"></button>')
  //                    .html('EDIT');
  //
  //            var _ = this;
  //            _ele.click(function() {
  //                _.open_overlay(jQuery(this));
  //            });
  //
  //            return _ele;
  //        },
          create_toggle_button: function() {
              var _ele = jQuery('<button type="button" class="toggle" style="margin: 1em 0;"></button>')
                      .html('EDIT');

              var _ = this;
              _ele.click(function() {
                  _.toggle_edit()
              });

              return _ele;
          },
          toggle_edit: function (_is_editing) {
              var _ = this;

              var _toggle = _.get_container().find("button.toggle");
              var _editor = _.get_container().find(".html-editor-container");
              var _view = _.get_container().find(".html-editor-view");

              if (_is_editing === undefined) {
                  _is_editing = (_view.filter(":visible").length > 0);
              }

              if (_is_editing === true) {
                  _view.hide();
                  _editor.show();
                  _toggle.html('PREVIEW');
              }
              else {
                  _view.show();
                  _editor.hide();
                  _toggle.html('EDIT');
              }
          },
  //        open_overlay: function(_btn) {
  //            //var _field = _btn.parents(this.config.field + ':first');
  //            var _ = this;
  //            var _field = _.get_container();
  //            var _hint = _field.find(this.config.hint + ":first");
  //            var _overlay = _hint.find('.zentyal-field-html-editor:first');
  //            //console.log(["overlay length", _overlay.length]);
  //            //_overlay.show();
  //
  //            //var _field = _overlay.parents(this.config.field + ':first');
  //            //alert(['input:text:first', _overlay.length, _field.length]);
  //            var _html = _field.find('input:first').val();
  //
  //            //alert(["html", _html]);
  //            _html = this.decode(_html);
  //
  //            var _tinymce_id = _overlay.find('textarea:first').attr('id');
  //            
  //            var _editor;
  //            
  //            var _ = this;
  //            var _loop = function () {
  //                var _editor = tinymce.get(_tinymce_id);
  //
  //                if (_editor !== undefined
  //                        && typeof(_editor.setContent) === "function") {
  //                    _editor.setContent(_html);
  //                }
  //                else {
  //                    return setTimeout(_loop, 100);
  //                }
  //
  //                // -------------------------
  //                setTimeout(function () {
  //                    _.resize_overlay();
  //                    //_overlay.show();
  //                    _overlay.fadeIn();
  //                    //alert(121212);
  //                }, 100);
  //            };
  //            
  //            _loop();
  //
  //            //_editor.height = '500px';
  //            //_overlay.find('textarea').val(_html);
  //        },
  //        resize_overlay: function() {
  //            var _overlay = jQuery('.zentyal-field-html-editor.overlay:visible:first');
  //            var _background = _overlay.find('.background:first');
  //            if (_overlay.length === 0) {
  //                return;
  //            }
  //
  //            //var _width = jQuery('body').width();
  //            var _width = window.innerWidth;
  //            var _height = window.innerHeight;
  //            var _padding_width = 50;
  //            var _padding_height = 50;
  //            //var _inner_width = _width - (_padding_width * 2);
  //            var _inner_height = _height - (_padding_height * 2) - 50;
  //
  //            if (_inner_height > 600) {
  //                _inner_height = 600;
  //            }

  //        console.log(
  //                _width + ', ' 
  //                + _height + ', '
  //                + _padding_height + ', '
  //                + _padding_height + ', ');
  //
  //            _background.css({
  //                'width': _width + 'px',
  //                'height': _height + 'px'
  //            });

              /*
              _overlay.find('.inner').css({
                  'width': _inner_width + 'px',
                  'height': _inner_height + 'px',
                  //'top': _padding_height + 'px',
                  //'left': _padding_width + 'px'

              });
              */
              //_overlay.find('.mce-edit-area > iframe').css('height', _inner_height + 'px');
  //        },
  //        close_overlay: function(_btn) {
  //            var _ = this;
  //            var _overlay = _btn.parents('.overlay:first');
  //            //_overlay.hide();
  //            _overlay.fadeOut();
  //
  //            var _tinymce_id = _overlay.find('textarea:first').attr('id');
  //            //console.log(_tinymce_id);
  //            var _html = tinymce.get(_tinymce_id).getContent();
  //            //console.log(_html);
  //            var _ori_html = _html;
  //            _html = this.encode(_html);
  //            //var _field = _overlay.parents(this.config.field + ':first');
  //            
  //            // 要把資料存進去
  //            var _field = _.get_container();
  //            var _input = _.get_input();
  //            _input.val(_html);
  //            
  //            var _view = _field.find('.html-editor .html-editor-view:first');
  //            if (_view.length === 1) {
  //                _view.html(_ori_html);
  //            }
  //        },

          // -------------------------------------------------------

          encode: function(_str) {
              //_str = escape(_str);
              //_str = jQuery('<span />').text(_str).html();
              //_str = Base64.encode(_str);
              _str = this.escapeToUtf16(_str);
              return _str;
          },
          decode: function(_str) {
              //_str = jQuery('<span />').html(_str).text();
              //_str = Base64.decode(_str);
              //_str = jQuery('<span />').html(_str).text();
              //console.log(["decode", _str, typeof(this.unescapeFromUtf16)]);
              _str = this.unescapeFromUtf16(_str);
              return _str;
          },

          /**
           * Author: Dark Launch
           * Code from http://darklaunch.com/tools/string-to-javascript-unicode
           */
          escapeToUtf16: function (str) {
              var escaped = "";
              for (var i = 0; i < str.length; ++i) {
                  var hex = str.charCodeAt(i).toString(16).toUpperCase();
                  escaped += "+" + "0000".substr(hex.length) + hex;
              }
              return escaped;
          },
          convertUtf16CodesToString: function (utf16_codes) {
              var unescaped = '';
              for (var i = 0; i < utf16_codes.length; ++i) {
                  unescaped += String.fromCharCode(utf16_codes[i]);
              }
              return unescaped;
          },
          convertEscapedCodesToCodes: function (str, prefix, base, num_bits) {
              var parts = [];
              parts = str.split(prefix);
              parts.shift();
              var codes = [];
              var max = Math.pow(2, num_bits);
              for (var i = 0; i < parts.length; ++i) {
                  var code = parseInt(parts[i], base);
                  if (code >= 0 && code < max) {
                      codes.push(code);
                  } 
                  else {

                  }
              }
              return codes;
          },
          convertEscapedUtf16CodesToUtf16Codes: function (str) {
              //if (str === undefined) {
              //    return [];
              //}
              return this.convertEscapedCodesToCodes(str, "+", 16, 16);
          },
          unescapeFromUtf16: function (str) {
              //console.log(['unescapeFromUtf16', str]);
              var utf16_codes = this.convertEscapedUtf16CodesToUtf16Codes(str);
              //console.log(['unescapeFromUtf16', utf16_codes]);
              return this.convertUtf16CodesToString(utf16_codes);
              //return str;
          }
      };
      
      return _ZENTYAL_UTIL
    }
      
    var _ZENTYAL_UTIL_init = function (id) {
      let z = create_ZENTYAL_UTIL()
      z.init(id)
    }

    //_ZENTYAL_UTIL.init();

}   // if (_ZENTYAL_UTIL === undefined) {
