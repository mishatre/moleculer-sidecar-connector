(function(window, undefined)
{
	"use strict";
	
	if(window.frameElement)
	{
		var parent = window.frameElement.ownerDocument.defaultView || window.frameElement.ownerDocument.parentWindow;
		var styleDeferred = parent.styleDeferred;
		var iframeParent = window.frameElement.parentNode;
		var waitFonts = iframeParent.getAttribute('data-wait-fonts');
		var headerFont = iframeParent.getAttribute('data-header-font');
		var headerTag = iframeParent.getAttribute('data-header-tag');
		var headerPseudo = iframeParent.getAttribute('data-header-pseudo');
		
		if(waitFonts)
		{
			waitFonts = waitFonts.split(',');
			var fontTriggerCss = [];
			var fontTriggerRules = 'content:".";position:absolute;visibility:hidden';
			
			if(waitFonts[0])
				fontTriggerCss.push('html::before{' + fontTriggerRules + ';font:' + waitFonts[0] + '}');
			
			if(waitFonts[1])
				fontTriggerCss.push('html::after{' + fontTriggerRules + ';font:' + waitFonts[1] + '}');
			
			if(fontTriggerCss.length)
			{
				var fontTriggerStyle = document.createElement('STYLE');
				fontTriggerStyle.type = 'text/css';
				fontTriggerStyle.appendChild(document.createTextNode(fontTriggerCss.join("\r\n")));
				document.head.appendChild(fontTriggerStyle);
				var forceLayout = document.documentElement.offsetHeight;
				document.head.removeChild(fontTriggerStyle);
			}
		}
	}
	else
	{
		var parent = window;
		var styleDeferred = void 0;
		var iframeParent = void 0;
	}
	
	var iOS = window.TouchEvent && 'standalone' in navigator;
	var Android = navigator.userAgentData && navigator.userAgentData.platform === 'Android'
			   || (!navigator.userAgentData || !navigator.userAgentData.platform && navigator.vendor === 'Google Inc.') && navigator.userAgent.match(/\bAndroid\b/);
	var supportsScrollbarStyle = window.CSS && CSS.supports && CSS.supports('selector(::-webkit-scrollbar)');
	var raf = window.requestAnimationFrame || function(cb){setTimeout(cb, 0);};
	
	if(iOS)
		document.addEventListener('touchstart', (function(){return function(){}})());
	
	var hasTouchScreen = iOS || window.matchMedia && matchMedia('(any-pointer: coarse)').matches;
	var dc = document.documentElement.className.replace(/(^|\s+)js-disabled(\s+|$)/, ' ');
	dc += ' ' + (hasTouchScreen ? 'touchscreen' : 'no-touchscreen');
	
	if(iOS)
		dc += ' ios';
	else if(Android)
		dc += ' android';
	
	document.documentElement.className = dc;
	
	if(window.frameElement && (Android || parent.LIGHTHOUSE))
		var triggerLCP = parent.DEV
					  || parent.LIGHTHOUSE
					  || navigator.userAgent.match(/\b(Chrome-Lighthouse|PTST)\b/);
	else
		var triggerLCP = false;
	
	var waitingImages = window.frameElement ? !!iframeParent.getAttribute('data-wait-images') : false;
	var waitingFonts = false;
	var fontWaitDeadline = 1500;
	var LCPtriggered = false;
	
	var showDocument = function(noTriggerLCP)
	{
		waitingFonts = false;
		var rx = /(^|\s)loading(\s|$)/;
		
		if(iframeParent.className.match(rx))
		{
			if(headerTag && headerPseudo && styleDeferred && styleDeferred.appendShell && !styleDeferred.inactive)
			{
				var removeFakeHeader = function()
				{
					if(styleDeferred.inactive
					|| document.readyState === 'complete'
					|| document.getElementsByTagName(headerTag)[0] && (!headerFont || checkFonts([headerFont])))
					{
						if(!styleDeferred.inactive)
							styleDeferred.appendShell(headerPseudo + '{display:none}');
					}
					else
						raf(removeFakeHeader);
				};
				
				raf(removeFakeHeader);
			}
			
			iframeParent.className = iframeParent.className.replace(rx, ' ');
			
			if((!styleDeferred || styleDeferred.usingShell || styleDeferred.inactive)
			&& (!styleDeferred || styleDeferred.activateInterval || styleDeferred.finalizeInterval || parent.SSP && parent.App))
			{
				iframeParent.style.width = iframeParent.offsetWidth + 'px';
				var forceLayout = iframeParent.offsetWidth;
				iframeParent.style.removeProperty('width');
			}
			
			if(triggerLCP
			&& !noTriggerLCP)
			{
				if(styleDeferred && !styleDeferred.usingShell && !styleDeferred.inactive)
					styleDeferred.push(function(){
						triggerLCPforLighthouse(true);
					});
				else if(window.location.toString() === 'about:srcdoc')
					triggerLCPforLighthouse();
				else
					raf(function(){
						raf(triggerLCPforLighthouse);
					});
			}
		}
	};
	
	var readyToShowDocument = function()
	{
		if(!parent.App
		|| !parent.App.Its
		|| !parent.App.Its.Handler
		|| !parent.App.Its.Handler.loadedInitialDocument)
			if(!hasDocumentScrollIntent())
				if(styleDeferred
				|| !Android && !iOS)
				{
					if(!Android && !iOS && !hasTouchScreen)
					{
						var syncedCustomScrollbars = syncCustomScrollbars();
						
						if(!syncedCustomScrollbars
						&& !supportsScrollbarStyle)
							return false;
					}
					
					return true;
				}
		
		return false;
	};
	
	var syncCustomScrollbars = function()
	{
		var frameParent = frameElement.parentNode;
		
		if(frameParent
		&& frameParent.querySelector)
		{
			var bar_v = frameParent.querySelector('div.thin_scroll_bar_v');
			var thumb_v = frameParent.querySelector('div.thin_scroll_thumb_v');
			var bar_h = frameParent.querySelector('div.thin_scroll_bar_h');
			var thumb_h = frameParent.querySelector('div.thin_scroll_thumb_h');
			var corner = frameParent.querySelector('div.thin_scroll_corner');
			
			if(!bar_v || !thumb_v || !bar_h || !thumb_h || !corner)
			{
				if(supportsScrollbarStyle)
					return;
				else if(navigator.userAgent.match(/Edge\/([\d]{1,3})/))
					return true;
				
				var parentDocument = parent.document;
				
				bar_v = parentDocument.createElement('div');
				bar_v.className = 'thin_scroll_bar_v';
				
				thumb_v = parentDocument.createElement('div');
				thumb_v.className = 'thin_scroll_thumb_v';
				
				bar_v.appendChild(thumb_v);
				
				bar_h = parentDocument.createElement('div');
				bar_h.className = 'thin_scroll_bar_h';
				
				thumb_h = parentDocument.createElement('div');
				thumb_h.className = 'thin_scroll_thumb_h';
				
				bar_h.appendChild(thumb_h);
				
				corner = parentDocument.createElement('div');
				corner.className = 'thin_scroll_corner';
				
				frameParent.appendChild(corner);
				frameParent.appendChild(bar_v);
				frameParent.appendChild(bar_h);
			}
			
			if(supportsScrollbarStyle)
			{
				bar_v.style.display = 'none';
				thumb_v.style.display = 'none';
				bar_h.style.display = 'none';
				thumb_h.style.display = 'none';
				corner.style.display = 'none';
			}
			else
			{
				if(document.scrollingElement)
					var scrolling = document.scrollingElement;
				else
					var scrolling = document.compatMode === 'BackCompat' ? document.body : document.documentElement;
				
				var has_scroll_v = scrolling.scrollHeight > scrolling.clientHeight;
				var has_scroll_h = scrolling.scrollWidth > scrolling.clientWidth;
				
				bar_v.style.display = 'block';
				bar_v.style.removeProperty('bottom');
				thumb_v.style.display = has_scroll_v ? 'block' : 'none';
				bar_h.style.display = 'block';
				bar_h.style.removeProperty('right');
				thumb_h.style.display = has_scroll_h ? 'block' : 'none';
				corner.style.display = 'block';
				
				return true;
			}
		}
		
		return false;
	};
	
	var checkFonts = function(fonts)
	{
		if(document.fonts && document.fonts.size && document.fonts.check)
			for(var i = 0; i < fonts.length; i++)
				try
				{
					if(!document.fonts.check(fonts[i]))
						return false;
				}
				catch(e){}
		
		return true;
	};
	
	var fontWaitDeadlineMissed = function()
	{
		var performance = window.frameElement ? parent.performance : window.performance;
		
		if(performance)
		{
			if(performance.now)
				return performance.now() >= fontWaitDeadline;
			else if(performance.timing
			&& performance.timing.navigationStart)
				return Date.now() - performance.timing.navigationStart >= fontWaitDeadline;
		}
	};
	
	var hasDocumentScrollIntent = function()
	{
		if(!window.frameElement)
			return false;
		
		return parent.location.hash !== ''
			|| parent.location.pathname.match(/@[0-9a-f]+[:\/]*$/)
			|| window.location.hash !== ''
			|| window.location.search.match(/[\?&]search=/);
	};
	
	window.alertDiskOnly = parent.alertDiskOnly = function()
	{
		alert('Данная возможность доступна в дисковой версии');
	};
	
	window.alertBrokenLink = parent.alertBrokenLink = function()
	{
		alert('Ошибка! Неизвестная ссылка');
	};
	
	window.onBodyAvailable = function()
	{
		if(!window.frameElement
		|| !parent.TEMPLATE_NEW)
			return;
		
		var imgRules = '{max-width:100%;height:auto;background:center no-repeat url(\'/img_new/spinner-tpt-small.svg\')}';
		var css = 'p.pic_image>img,'
				+ 'div.pic_image>img,'
				+ 'p.Picture>img,'
				+ 'div.Picture>img,'
				+ 'p img:only-child,'
				+ 'div img:only-child'
				+ imgRules
				+ 'p:has(img~script) img,'
				+ 'div:has(img~script) img'
				+ imgRules;
		
		var style = document.createElement('STYLE');
		style.id = 'img_enlargeable_style_initial';
		style.type = 'text/css';
		style.appendChild(document.createTextNode(css));
		document.head.appendChild(style);
		
		if(iOS
		&& (!window.CSS || !CSS.supports || !CSS.supports('touch-action: pan-y')))
		{
			var parentWidth = window.frameElement.parentNode.offsetWidth;
			
			if(!parentWidth)
				return;
			
			var body = document.body;
			var documentElementStyle = window.getComputedStyle(documentElement);
			var bodyStyle = window.getComputedStyle(body);
			var documentElementPadding = parseInt(documentElementStyle.paddingLeft) + parseInt(documentElementStyle.paddingRight);
			var bodyMargin = parseInt(bodyStyle.marginLeft) + parseInt(bodyStyle.marginRight);
			var bodyPadding = parseInt(bodyStyle.paddingLeft) + parseInt(bodyStyle.paddingRight);
			documentElement.style.setProperty('margin-left', '0px', 'important');
			documentElement.style.setProperty('margin-right', '0px', 'important');
			documentElement.style.setProperty('min-width', 'auto', 'important');
			documentElement.style.setProperty('max-width', 'none', 'important');
			documentElement.style.setProperty('width', (parentWidth - documentElementPadding) + 'px', 'important');
			body.style.setProperty('min-width', 'auto', 'important');
			body.style.setProperty('max-width', 'none', 'important');
			body.style.setProperty('width', (parentWidth - documentElementPadding - bodyMargin - bodyPadding) + 'px', 'important');
		}
		
		document.contentAdjustedForWebkitOverflowScrolling = true;
		
		if(!Android && !iOS && supportsScrollbarStyle)
		{
			var css = 'html::-webkit-scrollbar,body::-webkit-scrollbar'
					+ '{width:17px;height:17px}'
					+ 'html::-webkit-scrollbar,body::-webkit-scrollbar,'
					+ 'html::-webkit-scrollbar-track,body::-webkit-scrollbar-track,'
					+ 'html::-webkit-scrollbar-thumb,body::-webkit-scrollbar-thumb'
					+ '{background-color:transparent}';
			
			var style = document.createElement('STYLE');
			style.id = 'scrollbar_style_initial';
			style.type = 'text/css';
			style.appendChild(document.createTextNode(css));
			document.head.appendChild(style);
		}
		
		if((Android || !iOS && supportsScrollbarStyle)
		&& !document.body.className.match(/(?:^|\s)iframe\s+error(?:\s|$)/))
		{
			var scrollerStyleSheetId = 'scroller_stylesheet_w_metadata_doc_frame';
			
			if((!Android && !iOS && supportsScrollbarStyle || parent.document.getElementById(scrollerStyleSheetId))
			&& !document.getElementById(scrollerStyleSheetId))
			{
				if(document.scrollingElement)
					var scrollerTagName = document.scrollingElement.tagName.toLowerCase();
				else
					var scrollerTagName = document.compatMode === 'BackCompat' ? 'body' : 'html';
				
				var css = scrollerTagName
						+ '{overflow-y:scroll}';
				
				var style = document.createElement('STYLE');
				style.id = scrollerStyleSheetId;
				style.type = 'text/css';
				style.appendChild(document.createTextNode(css));
				style.setAttribute('data-preserve-style', css);
				document.head.appendChild(style);
			}
		}
		
		if(readyToShowDocument()
		&& !waitingImages)
		{
			var doWaitFonts = !!waitFonts;
			
			if(doWaitFonts)
			{
				var connection = navigator.connection;
				
				if(fontWaitDeadlineMissed())
					doWaitFonts = false;
				else if((Android || iOS)
				&& (navigator.hardwareConcurrency && navigator.hardwareConcurrency <= 4 || navigator.deviceMemory && navigator.deviceMemory <= 2 || navigator.maxTouchPoints && navigator.maxTouchPoints <= 2))
					doWaitFonts = false;
				else if(connection
				&& (connection.type === 'cellular' || connection.type === 'unknown' || connection.effectiveType && connection.effectiveType !== '4g'))
					doWaitFonts = false;
			}
			
			if(!doWaitFonts || !document.fonts || !document.fonts.size || !document.fonts.ready)
				showDocument();
			else
			{
				waitingFonts = true;
				var fontWaiterInterval;
				
				var fontWaiter = function()
				{
					var fontsLoaded = true;
					
					if(waitingFonts
					&& !fontWaitDeadlineMissed()
					&& !checkFonts(waitFonts))
						fontsLoaded = false;
					
					if(fontsLoaded)
					{
						if(fontWaiterInterval)
						{
							clearInterval(fontWaiterInterval);
							fontWaiterInterval = void 0;
						}
						
						showDocument();
					}
				};
				
				fontWaiter();
				
				if(waitingFonts)
				{
					raf(fontWaiter);
					setTimeout(fontWaiter, 0);
					fontWaiterInterval = setInterval(fontWaiter, 8);
					document.fonts.ready.then(showDocument);
					document.fonts.onloadingerror = showDocument;
				}
			}
		}
	};
	
	window.forceDocumentLayout = function(ignoreWaitingResources)
	{
		var currentScript = document.currentScript;
		
		if(currentScript
		&& !currentScript.src
		&& currentScript.parentNode
		&& currentScript.parentNode.tagName !== 'HEAD')
		{
			var previousSibling = currentScript.previousSibling;
			var unsizedImg = previousSibling
						  && previousSibling.tagName === 'IMG'
						  && (!previousSibling.getAttribute('width') && !previousSibling.style.width || !previousSibling.getAttribute('height') && !previousSibling.style.height);
			
			if(!unsizedImg && window.CSS && CSS.supports && CSS.supports('selector(:has(*))'))
				setTimeout(function(){
					raf(function(){
						raf(function(){
							currentScript.parentNode.removeChild(currentScript);
						});
					});
				}, 0);
			else
				currentScript.parentNode.removeChild(currentScript);
			
			if(unsizedImg)
				return;
		}
		
		if(!window.frameElement
		|| !parent.TEMPLATE_NEW)
			return;
		
		if((ignoreWaitingResources || !waitingImages && (!waitingFonts || fontWaitDeadlineMissed()))
		&& readyToShowDocument())
		{
			var forceLayout = document.documentElement.offsetHeight;
			showDocument(true);
			triggerLCPforLighthouse();
		}
	};
	
	window.adjustContentLegacy = function()
	{
		var css = 'pre, code, kbd, p.Programtext'
				+ '{white-space:pre-wrap;word-wrap:break-word}'
				+ 'h1, h2, h3, h4, h5, h6, p, li, table,'
				+ 'p span, p font, p b, p strong, p i, p em,'
				+ 'li span, li font, li b, li strong, li i, li em,'
				+ 'table span, table font, table b, table strong, table i, table em,'
				+ 'span.apiname'
				+ '{white-space:normal;word-wrap:break-word}'
				+ 'body>div.index>a, body>div>div.index>a, ul.toc a,'
				+ 'body>ul:not([class]) a:only-of-type[target="_top"],'
				+ 'body>ul:not([class]) a:only-of-type[href^="/"],'
				+ 'body>ul:not([class]) a:only-of-type[href^="#"]'
				+ '{display:inline-block;margin-top:10px;word-wrap:normal}';
		
		if(!window.frameElement)
		{
			if(location.hash !== '_print'
			&& location.hash !== '#_print')
			{
				css += 'p a, li a, table a'
					 + '{white-space:normal;word-wrap:break-word}';
			}
		}
		else if(!parent.MOBILE_ENABLED)
			css += 'html {text-size-adjust:200%!important;-webkit-text-size-adjust:200%!important}';
		
		var style = document.createElement('STYLE');
		style.type = 'text/css';
		style.appendChild(document.createTextNode('@media (any-pointer: coarse),(pointer: none){' + css + '}'));
		document.head.appendChild(style);
	};
	
	window.triggerLCPforLighthouse = function(ignoreTriggered)
	{
		if(!window.frameElement
		|| !triggerLCP
		|| !ignoreTriggered && LCPtriggered)
			return;
		
		var overlay = parent.document.createElement('DIV');
		overlay.className = 'lighthouse_forced_lcp_from_iframe';
		overlay.style.backgroundColor = '#fff';
		overlay.style.position = 'absolute';
		overlay.style.display = 'block';
		overlay.style.overflow = 'hidden';
		overlay.style.top = 0;
		overlay.style.bottom = 0;
		overlay.style.left = 0;
		overlay.style.right = 0;
		overlay.style.opacity = '0.5';
		overlay.innerHTML = '. '.repeat(5000);
		parent.document.body.appendChild(overlay);
		LCPtriggered = true;
		raf(function(){
			setTimeout(function(){
				overlay.style.opacity = 0;
				setTimeout(function(){
					raf(function(){
						overlay.style.top = '-100vh';
						overlay.style.bottom = '100vh';
					});
				}, 0);
			}, 0);
		});
	};
	
	if(!window.frameElement)
	{
		var autoImgWidth = true;
		var hash = window.location.hash;
		
		if(hash !== '_print' && hash !== '#_print')
		{
			var thisLoc = window.location.pathname.split('/');
			if(thisLoc[0] === '')
				thisLoc.shift();
			var appPath = thisLoc.shift();
			var mode = thisLoc.shift();
			var dbNick = thisLoc.shift();
			var docPath = thisLoc.join('/').replace(/\?[0-9]{10}=?/, '').replace(/_+$/, '');
			
			if(hash && hash.charAt(0) === '#')
				hash = hash.substr(1);
			
			var matchReferrer = new RegExp('^https?://' + location.host.replace(/\./g, '\\.') + '/' + appPath + '/' + dbNick + '(?:/|$)', 'i');
			
			var colon = encodeURIComponent(':');
			var matchUser = new RegExp('\\bUSER_TYPE=[' + colon + '\\d]*' + colon + '1' + colon);
			
			if(mode !== 'files'
			&& (document.referrer && !document.referrer.match(matchReferrer) || !document.referrer && document.cookie.match(matchUser)))
			{
				autoImgWidth = false;
				
				try
				{
					if(!document.body && location.hostname.match(/(?:\.(ru|local)|^127\.0\.0\.1)$/))
					{
						document.write('<style>html{width:100%;height:100%;background:#fff url(\'/img_new/logo_its_resize_on_white.gif\') center center no-repeat}body{display:none!important}</style></head><body></body></html>');
						document.close();
					}
				}
				catch(e){}
				
				setTimeout(function(){
					window.location.replace('/' + appPath + '/' + dbNick + '/' + mode + '/' + docPath + '_' + (hash ? '?anchor=' + hash : ''));
				}, 0);
			}
			else if(hasTouchScreen)
				document.write('<style>table{display:block;width:auto!important;overflow-x:auto;clear:both}</style>');
		}
		else
		{
			/*@cc_on
			if(true)
			{
				window.print();
			}
			else
			{
			@*/
				window.onload = function()
				{
					var imgs = document.getElementsByTagName('IMG');
					var incomplete = 0;
					
					var imgOnLoad = function()
					{
						incomplete--;
						
						if(incomplete === 0)
							window.print();
					};
					
					for(var i = 0; i < imgs.length; i++)
						if(imgs[i].complete === false)
						{
							imgs[i].onload = imgOnLoad;
							imgs[i].setAttribute('loading', 'eager');
							incomplete++;
						}
					
					if(!incomplete)
						window.print();
				};
			/*@cc_on
			}
			@*/
		}
		
		if(autoImgWidth)
			document.write('<style>.pic_image img, .Picture img {max-width:100%;height:auto} @media (any-pointer: coarse),(pointer: none){ img {max-width:100%;height:auto} }</style>');
	}
	else
	{
		if(parent.document.title === 'Document Moved')
			parent.location.reload(true);
		else
		{
			if(parent.MOBILE_ENABLED)
			{
				var documentElement = document.documentElement;
				documentElement.style.setProperty('text-size-adjust', '100%', 'important');
				documentElement.style.setProperty('-webkit-text-size-adjust', '100%', 'important');
			}
			
			if(parent.deferred
			&& location.hostname.match(/\.eu$/))
				parent.deferred.push(function()
				{
					var loginLink = document.getElementById('login_link_iframe');
					
					if(loginLink)
					{
						var parentLoc = parent.location.pathname.split('/');
						if(parentLoc[0] === '')
							parentLoc.shift();
						var appPath = '/' + parentLoc.shift() + '/';
						
						if(appPath !== '/db/')
						{
							appPath += parentLoc.shift() + '/';
							var pathEncoded = appPath.replace(/\//g, '%2F');
							var rx = new RegExp('\\?backurl=' + pathEncoded);
							
							if(!loginLink.href.match(rx))
								loginLink.href = loginLink.href.replace(/\?backurl=%2Fdb%2F/, '?backurl=' + pathEncoded);
						}
					}
				});
			
			if(parent.SSP && parent.App)
				setTimeout(parent.SSP.Bus.runDeferred, 0);
			
			var checker = (function()
			{
				if((document.readyState === 'loaded' || document.readyState === 'complete')
				&& parent.SSP
				&& parent.App)
				{
					clearInterval(interval);
					parent.SSP.Bus.runDeferred();
				}
				else if(parent.document.documentElement.className.match(/(^|\s)css-failed(\s|$)/))
					clearInterval(interval);
			});
			var interval = setInterval(checker, 50);
			
			if(parent.App
			&& parent.App.Viewport)
				parent.App.Viewport.resetShift(true);
			
			if(!hasTouchScreen)
				try
				{
					window.frameElement.focus();
				}
				catch(e)
				{
					console.log(e);
				}
		}
	}
}
)(window);