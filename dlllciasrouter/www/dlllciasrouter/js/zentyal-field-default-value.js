if (typeof(ZENTYAL_FIELD_DEFAULT_VALUE) === 'undefined') {
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
  
  ZENTYAL_FIELD_DEFAULT_VALUE = async function (scriptElement, defaultValue) {
    if (!scriptElement) {
      console.error('no script element')
      return false
    }
    
    if (!defaultValue || defaultValue === '') {
      console.error('no default value')
      return false
    }
    
    await load_jquery()
    
    scriptElement = jQuery('#' + scriptElement)
    if (scriptElement.length === 0) {
      console.error('no script element: ' + scriptElement)
      return false
    }
    
    let input = scriptElement.parents('div:first').find('input:first')
    
    if (input.val() !== '') {
      return false
    }
    
    input.val(defaultValue)
  }
}