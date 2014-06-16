/**
 * The input contains invalid characters. All alphanumeric characters, 
 * plus these non alphanumeric chars: /.?&+:-@ and spaces are allowed.
 */
if (_ZENTYAL_UTIL === undefined) {

    var _ZENTYAL_UTIL = {
        config: {
            field: 'td',
            hint: '.html-editor'
        },
        init: function() {
            var _ = this;

            this.load_jquery(function() {
                _.load_tinymce(function() {
                    
                    var _after_init = function () {
                        var _trigger = jQuery(".init-button.trigger");
                        //alert([jQuery(".init-button").length]);
                        //alert([_trigger.length, _trigger.parents(_.config.field + ":first").length, _trigger.parents(_.config.field + ":first").find("button.edit").length]);
                        var _edit_button = _trigger.parents(_.config.field + ":first").find("button.edit");

                        jQuery(".init-button:visible").remove();

                        _edit_button.click();

                        jQuery(window).resize(function() {
                            console.log('resized');
                            _.resize_overlay();
                        });
                    };
                    
                    //_.main();
                    _.main();
                    
                    setTimeout(_after_init, 100);

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
        main: function() {
            var _ = this;
            var _selector = '.html-editor:not(.inited):visible';

            jQuery(_selector).each(function(_i, _hint) {
                _hint = jQuery(_hint);

                var _textarea = _.create_overlay();

                _hint.append(_textarea);

                var _btn = _.create_edit_button();

                _hint.prepend(_btn);
                
                var _field_container = _hint.parents(_.config.field + ':first');
                var _input = _field_container.find('input:text:first');
                _input.hide();
                var _view = _field_container.find('.html-editor .html-editor-view');
                
                var _str = _input.val();
                _str = _.decode(_str);
                _view.html(_str);
                
                _hint.addClass("inited");
            });
            //console.log("ready init");
            tinymce.init({
                selector: 'textarea.html-editor',
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
                image_advtab: true
            });
        },
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
            _str = this.unescapeFromUtf16(_str);
            return _str;
        },
        jquery_url: 'https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/jquery.min.js',
        //jquery_url: 'http://pc-pudding-2013.dlll.nccu.edu.tw/zentyal-dlll/zentyal-field/jquery.min.js',
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
        tinymce_url: 'https://dl.dropboxusercontent.com/u/717137/20140615-dlll-cias/tinymce/js/tinymce/tinymce.min.js',
        //tinymce_url: 'http://pc-pudding-2013.dlll.nccu.edu.tw/zentyal-dlll/zentyal-field/tinymce/js/tinymce/tinymce.min.js',
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
            var _ele = jQuery('<div></div>')
                    .addClass('zentyal-field-html-editor')
                    .addClass('overlay');

            var _background = jQuery('<div />')
                    .addClass('background')
                    .appendTo(_ele);

            var _inner = jQuery('<div></div>')
                    .addClass('inner')
                    .appendTo(_ele);

            _inner.append('<textarea class="html-editor"></textarea>');

            var _ = this;
            var _btn = jQuery('<button type="button" class="close zentyal-field" id="close_zentyal_field"></button>')
                    .html('CLOSE')
                    .appendTo(_inner)
                    .click(function() {
                        _.close_overlay(jQuery(this));
                    });

            _background.css({
                'background-color': 'black',
                'opacity': '0.7',
                'position': 'fixed',
                'width': '100%',
                'height': "100%",
                "padding-top": "30px",
                'top': '0px',
                'left': '0px'
            });

            _inner.css({
                'width': "80%",
                "margin-left": "10%",
                "margin-right": "auto",
                //'padding': "50px",
                'text-align': 'center',
                'position': 'fixed',
                'top': "10%",
                'left': 0
                        //'background-color': 'white'
            });

            _ele.hide();

            return _ele;
        },
        create_edit_button: function() {
            var _ele = jQuery('<button type="button" class="edit"></button>')
                    .html('EDIT');

            var _ = this;
            _ele.click(function() {
                _.open_overlay(jQuery(this));
            });

            return _ele;
        },
        open_overlay: function(_btn) {
            var _field = _btn.parents(this.config.field + ':first');
            var _hint = _field.find(this.config.hint + ":first");
            var _overlay = _hint.find('.zentyal-field-html-editor:first');
            //_overlay.show();

            //var _field = _overlay.parents(this.config.field + ':first');
            //alert(['input:text:first', _overlay.length, _field.length]);
            var _html = _field.find('input:text:first').val();

            //alert(["html", _html]);
            _html = this.decode(_html);

            var _tinymce_id = _overlay.find('textarea:first').attr('id');
            
            var _editor;
            
            var _ = this;
            var _loop = function () {
                var _editor = tinymce.get(_tinymce_id);

                if (_editor !== undefined
                        && typeof(_editor.setContent) === "function") {
                    _editor.setContent(_html);
                }
                else {
                    setTimeout(_loop, 100);
                }

                // -------------------------
                setTimeout(function () {
                    _.resize_overlay();
                    _overlay.fadeIn();
                }, 1000);
            };
            
            _loop();

            //_editor.height = '500px';
            //_overlay.find('textarea').val(_html);
        },
        resize_overlay: function() {
            var _overlay = jQuery('.zentyal-field-html-editor.overlay:visible:first');
            var _background = _overlay.find('.background:first');
            if (_overlay.length === 0) {
                return;
            }

            //var _width = jQuery('body').width();
            var _width = window.innerWidth;
            var _height = window.innerHeight;
            var _padding_width = 50;
            var _padding_height = 50;
            var _inner_width = _width - (_padding_width * 2);
            var _inner_height = _height - (_padding_height * 2) - 50;

            if (_inner_height > 600) {
                _inner_height = 600;
            }

//        console.log(
//                _width + ', ' 
//                + _height + ', '
//                + _padding_height + ', '
//                + _padding_height + ', ');

            _background.css({
                'width': _width + 'px',
                'height': _height + 'px'
            });

            /*
            _overlay.find('.inner').css({
                'width': _inner_width + 'px',
                'height': _inner_height + 'px',
                //'top': _padding_height + 'px',
                //'left': _padding_width + 'px'
                
            });
            */
            //_overlay.find('.mce-edit-area > iframe').css('height', _inner_height + 'px');
        },
        close_overlay: function(_btn) {
            var _overlay = _btn.parents('.overlay:first');
            //_overlay.hide();
            _overlay.fadeOut();

            var _tinymce_id = _overlay.find('textarea:first').attr('id');
            //console.log(_tinymce_id);
            var _html = tinymce.get(_tinymce_id).getContent();
            //console.log(_html);
            var _ori_html = _html;
            _html = this.encode(_html);
            var _field = _overlay.parents(this.config.field + ':first');
            _field.find('input:text:first').val(_html);
            
            var _view = _field.find('.html-editor .html-editor-view:first');
            if (_view.length === 1) {
                _view.html(_ori_html);
            }
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
            var parts = str.split(prefix);
            parts.shift();
            var codes = [];
            var max = Math.pow(2, num_bits);
            for (var i = 0; i < parts.length; ++i) {
                var code = parseInt(parts[i], base);
                if (code >= 0 && code < max) {
                    codes.push(code);
                } else {
                }
            }
            return codes;
        },
        convertEscapedUtf16CodesToUtf16Codes: function (str) {
            return this.convertEscapedCodesToCodes(str, "+", 16, 16);
        },
        unescapeFromUtf16: function (str) {
            var utf16_codes = this.convertEscapedUtf16CodesToUtf16Codes(str);
            return this.convertUtf16CodesToString(utf16_codes);
        }
    };

    

    _ZENTYAL_UTIL.init();

}   // if (_ZENTYAL_UTIL === undefined) {
