<!DOCTYPE html>
<html>
    <head>
        <title>系統發生錯誤</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <link href="https://dl.dropboxusercontent.com/u/717137/20130914-error_page/css/reset.css" rel="stylesheet" type="text/css">	
	<link href="https://dl.dropboxusercontent.com/u/717137/20130914-error_page/css/styles.css" rel="stylesheet" type="text/css">
	<!--[if LTE IE 8]>
		<link href="css/ie.css" rel="stylesheet" type="text/css">
	<![endif]-->
	<!--[if IE 6]>
		<script type="text/javascript" src="js/DD_belatedPNG_0.0.8a-min.js"></script>
		<script type="text/javascript">
			DD_belatedPNG.fix('#bg-top, #bg-bottom, #logo, #nav ul, #contentWrap, #content, #leftColumn');
		</script>
	<![endif]-->
        <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js"></script>
        <script type="text/javascript" src="https://dl.dropboxusercontent.com/u/717137/20130914-error_page/js/jquery.pietimer.js"></script>
        <style type="text/css">
#timer {
    margin: 10px;
    width: 80px;
}
 
.pietimer {
    position:relative;
    font-size: 200px;
    width:1em;
    height:1em;
}
.pietimer > .percent {
    position: absolute;
    top: 1.35em;
    left: 0;
    width: 3.33em;
    font-size: 0.3em;
    text-align:center;
    display: none;
}
.pietimer > .percent .unit {
    font-size: 0.2em;
}
.pietimer > .slice {
    position:absolute;
    width:1em;
    height:1em;
    clip:rect(0px,1em,1em,0.5em);
}
.pietimer > .slice.gt50 {
    clip:rect(auto, auto, auto, auto);
}
.pietimer > .slice > .pie {
    border: 0.1em solid #c0c0c0;
    position:absolute;
    width:0.8em; /* 1 - (2 * border width) */
    height:0.8em; /* 1 - (2 * border width) */
    clip:rect(0em,0.5em,1em,0em);
    -moz-border-radius:0.5em;
    -webkit-border-radius:0.5em;
    border-radius:0.5em;
}
.pietimer > .slice > .pie.fill {
    -moz-transform:rotate(180deg) !important;
    -webkit-transform:rotate(180deg) !important;
    -o-transform:rotate(180deg) !important;
    transform:rotate(180deg) !important;
}
.pietimer.fill > .percent {
    display: none;
}
.pietimer.fill > .slice > .pie {
    border: transparent;
    background-color: #c0c0c0;
    width:1em;
    height:1em;
}
        </style>
    </head>
    <body>
        

<script type="text/javascript">
    var DO_REFRESH = true;
    $(function() {
      $('#timer').pietimer({
          timerSeconds: 300,
          color: '#188ECE',
          fill: false,
          showPercentage: true,
          callback: function() {
              if (DO_REFRESH) {
                location.reload(true);
              }
          }
      });
      
      var _url = location.href;
      var _url_a = '<a href="'+_url+'">'+_url+'</a>';
      $(".ori-url").html(_url_a);
      $(".this-page").attr('href', _url);
      
      // 送出訊息
      $.get( "restarter_action.php" );
    });

    function cancel_refresh() {
      DO_REFRESH = false;
      $('#timer').hide();
      $('#cancelButton').hide();
    }
</script>
        
	<div id="wrapper">

		<div id="bg-top"></div>
		<div id="contentWrap">
        <div id="content">
				
				<!-- BEGIN LEFT COLUMN -->
				<div id="leftColumn">
				
					<!-- YOUR LOGO GOES HERE -->
					<a href="http://dlll.nccu.edu.tw/" class="logo">
                                            <!-- <img id="logo" src="images/template/logo.png" alt="Logo Sample" width="222" height="100"> -->
                                            <span>數位圖書館暨<br/>數位學習實驗室</span>
                                        </a>
					
					<!-- BEGIN MENU -->
					<div id="nav">

						<span>連結</span>
						<ul>
							<li class="home"><a href="http://dlll.nccu.edu.tw/">實驗室</a></li>
							<li class="about"><a href="http://dlll.nccu.edu.tw/?page_id=10">指導教授</a></li>
							<li class="contact"><a href="mailto:pudding@nccu.edu.tw">聯絡我們</a></li>
						</ul>
					</div><!-- end div #nav -->

					
					<!-- ERROR CODE HERE -->
					<h1 style="font-size: 60px;cursor: default;">SYSTEM<span>Error</span></h1>
				</div><!-- end div #leftColumn -->
				<!-- END LEFT COLUMN -->
				
				<!-- BEGIN RIGHT COLUMN -->
				<div id="rightColumn">
					<h2>糟糕！系統發生錯誤了...</h2>
                                         
                                         <div id="timer" style="float:right;"></div> <p>系統重新啟動中。距離啟動完成還有……</p>
                                         
                                         <p>啟動完成之後，您將會重新移動到原本造訪的網頁：<span class="ori-url"></span></p>
                                         <button id="cancelButton" onclick="cancel_refresh()">取消自動跳轉</button>
                                       <p style="clear:both;">如果重新啟動之後網頁依然無法運作，請<a href="mailto:pudding@nccu.edu.tw">聯絡網管人員</a>來協助您處理這個問題。</p>
                    
					<h4 class="regular"><strong>不知道該怎麼辦嗎？我們建議您……</strong></h4>
					<ol>
						<li><span>可能是短期內系統負荷過大，稍候一陣子再進入<a href="#" class="this-page">本網頁</a>看看。</span></li>

						<li><span>請<a href="mailto:pudding@nccu.edu.tw">聯絡網管人員</a>來協助您處理這個問題。</span></li>
						<li><span>從左邊連結來查看<a href="http://dlll.nccu.edu.tw/">實驗室網站</a>。</span></li>
						<!-- <li><span>using our site search below.</span></li> -->
					</ol>
					
					<!-- BEGIN SEARCH FORM - EDIT YOUR DOMAIN BELOW -->
                                        <form method="get" action="http://www.google.com/search" style="display:none;">

						<div>
							<input type="text" name="search" maxlength="255" value="search..." style="color: rgb(157, 157, 157);">
							<!--[if IE 6]><input type="submit" value="Go"><![endif]-->
							<!--[if !IE 6]><!--><input type="submit" value=""><!--<![endif]-->
							<input type="hidden" name="sitesearch" value="YOUR-DOMAIN.com">
						</div>
					</form>
					<!-- END SEARCH FORM -->
					
					<!-- <a id="close" href="javascript:void();">close</a> -->

					
				</div><!-- end div #rightColumn -->
				<!-- END RIGHT COLUMN -->
				
				<div class="clear"></div>
			</div>
                </div>
		<div id="bg-bottom"></div>
	</div><!-- end div #wrapper -->
    </body>
</html>
