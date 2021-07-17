if (typeof(ZENTYAL_FIELD_CACHE) === 'undefined') {
  let jquery_url = '/data/dlllciasrouter/js/jquery.min.js'
  let load_jquery = function() {
    return new Promise((resolve) => {
      //alert(typeof (jQuery));
      if (typeof (jQuery) !== 'undefined') {
          resolve();
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
              if (typeof (resolve) === 'function') {
                  resolve();
              }
          }
      };
      _script.onload = function() {
          if (typeof (resolve) === 'function') {
              setTimeout(function() {
                  resolve();
              }, 0);
          }
      };

      if (_head !== undefined) {
          _head.appendChild(_script);
      }
    })
  }
  
  ZENTYAL_FIELD_CACHE = async function (scriptElement) {
    let id = scriptElement
    if (!scriptElement) {
      console.error('no script element')
      return false
    }
    
    await load_jquery()
    
    scriptElement = jQuery('#' + scriptElement)
    if (scriptElement.length === 0) {
      console.error('no script element: ' + scriptElement)
      return false
    }
    
    let input = scriptElement.parents('div:first').find('input.inputText')
    if (input.val() !== '') {
      // 已經有資料了，不設定
      return false
    }
    
    
    // 嘗試從cache找尋資料
    let key = 'ZENTYAL_FIELD_CACHE_' + id
    let data = localStorage.getItem(key)
    if (data) {
      input.val(data)
    }
    
    input.change(function () {
      let value = this.value
      localStorage.setItem(key, value)
    })
  }
}