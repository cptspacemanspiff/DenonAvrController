/**
 * @author	y.kobayashi
 * @since	2008/12/26
 * @version	0.0.1
    ModelId
	EnModelUnknown(0)
	EnModelAVR16XX(1)
	EnModelAVR17XX(2)
	EnModelAVR19XX(3)
	EnModelAVR21XX(4)
	EnModelAVR23XX(5)
	EnModelAVR33XX(6)
	
	EnModelNR16XX(7)
	EnModelSR50XX(8)
	EnModelSR60XX(9)
	EnModelSR70XX(10)
	
	EnModelAVR45XX(11)
	EnModelAV7701(12)
	EnModelAV8801(13)

 */
var _bDebug = location.hostname.indexOf("localhost") != -1;
var g_xmlData = "";

/**
 * String�N���X��trim���\�b�h��ǉ�
 */
String.prototype.trim = function() {
	return this.replace(/^\s+|\s+$/g, '');
}

/**
 * �A�v���P�[�V�����J�n�B
 *
 * @since	2008/12/26
 * @version	0.0.1
 */
function appStart() {
	var fill = $("#fill");
	// �S�Ă̒ʐM�ɑ΂��ăC�x���g���X�i�o�^�B�ʐM���̓y�[�W�S�̂Ƀt�B���^���|����B
		$().ajaxSend(function(event, XMLHttpRequest, options) {
		if (isNaN(options.bFill) || options.bFill) {
			$("#fill").focus().css("display", "block");
		}
	}).ajaxComplete(function(event, XMLHttpRequest, options) {
		if (options.url.indexOf(".xml") < 0) {
			fill.css("display", "none");
		}
	}).ajaxError(function() {
		fill.css("display", "none");
	});
	// #fill �̒�����������
	$.get("/_fill.html", null, function(data, status) {
		fill.html(data);
	});
	// �A�v���P�[�V����������
		initApp();
	// asp�������p�ʐM
	var url;
	if (_bDebug) {
//		url = "./index.html.init.asp";
//		url = "../proxy.php?url=" + encodeURI("MainZone/index.html.init.asp");
	} else {
		url = "./index.html.init.asp";
	}
	$.get(url, null, function(data, status) {
		// ������Ԏ擾�J�n�B
		loadMainXml(true);
	}, "text");

	//��ʕ`�掞��Cookie��������
//	$("div.menuItem a").click(function(event) {
		$.cookie("ZoneName", $("title").html(), {
			expires: 365,
			path: '/'
		});
//		return true;
//	});
}

/**
 * �y�[�W�\���pxml�̓ǂݍ���
 *
 * @param {bool} bFill	�ʐM��"connecting"�\������Ȃ��true�B�����ĕ`�悩�����ĕ`�悩�Ő؂�ς���B
 */
function loadMainXml(bFill) {
	var url = "";
	if (_bDebug) {
//		url = "/proxy.php?url=" + encodeURI("goform/formMainZone_MainZoneXml.xml");
		url = "/goform/formMainZone_MainZoneXml.xml";
	} else {
		url = "/goform/formMainZone_MainZoneXml.xml";
	}
	// �ʐM���ɗ��ǂ݂̃����[�h�v���͒e���B
	if( !bFill && this.ajax ) {
		return;
	}
	this.ajax = $.ajax({
		url: url, // �ڑ���URL
		bFill: bFill,
		cache: false, // �L���b�V�����Ȃ�
		success: function(data) { // �ʐM�������̃R�[���o�b�N�֐�
			parent.ajax = null;
			data = $(data);
			if ( !bFill && g_xmlData && g_xmlData.text() == data.text()) {
				$("#fill").css("display", "none");
				return;
			}
			data.getValue = function(param) {
				var ret = this.find(param + " value");
				if (ret.length == 1) {
					return ret.text();
				} else {
					return ret;
				}
			}
			data.getVolume = function(vol) {
				if (vol == undefined) {
					vol = this.getValue("MasterVolume");
				}
				if (this.isAbsolute() ) {
					if (vol == "--") {
//						vol = -81.0;
						vol = -80.0;
					}
//					return (parseFloat(vol) + 81.0).toFixed(1).toString();
					return (parseFloat(vol) + 80.0).toFixed(1).toString();					
				} else {
					return vol + "dB";
				}
			}
			data.isAbsolute = function() {
				return this.getValue("VolumeDisplay") == "Absolute";
			}
			g_xmlData = data;
			parsePowerXml(data);
			parseFuncXml(data);
			parseSurroundXml(data);
			parseVolumeXml(data);
			$("#fill").css("display", "none");
		},
		error: function(XMLHttpRequest) { // �ʐM�G���[�������̃R�[���o�b�N�֐�
			parent.ajax = null;
			if ( bFill ) {
				alert("connection failed\n");
			}
		}
	});
}

/**
 * �A�v���P�[�V�����̏������B�C�x���g���X�i�̓o�^�ȂǁB
 *
 * @since	2008/12/26
 * @version	0.0.1
 */
function initApp() {
	// �����[�h�{�^���̃C�x���g�n���h���o�^
	$("div#Reload a").click(function(event) {
		location.reload();
		return false;
	});
// �����N�N���b�N����cookie��zone������������ł����B�Ƃ肠����365���ԗL���B
//	$("div.menuItem a").click(function(event) {
//		$.cookie("ZoneName", $("title").html(), {
//			expires: 365,
//			path: '/'
//		});
//		return true;
//	});

	// Add To Your Favorite
	if ($.browser.mozilla || $.browser.msie || $.browser.opera) {
		$("div#Favorite a").click(function(event) {
			try {
				if ($.browser.mozilla) { // FireFox��
					window.sidebar.addPanel($("title").html(), window.location.href, '');

				} else if ($.browser.msie) { // IE
					window.external.AddFavorite(window.location.href, $("title").html());

				} else if ($.browser.opera) { // OPERA
					var a = event.target;
					a.rel = "sidebar";
					a.target = "_search";
					a.href = "url";
					return true;

				} else {
					throw "";
				}
			} catch (e) {
				$("div#Favorite").css("visibility", "hidden");
			}
			return false;
		});
	} else {
		$("div#Favorite").css("visibility", "hidden");
	}

	// Sleep
	$( "div#SleepTimer select" ).change(function(event){
		putRequest({
			cmd0: "PutSleepTimer/" + event.target.value,
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
		return false;
		event.target.selectedIndex = 0;
	});

}

/**
 * �}�E�X�I�[�o�[�ŉ摜�����ւ�����a�^�O�𐶐�����B
 *
 * @since 2009/1/14
 * @param {int} x	x�T�C�Y�B30/60/90/180�̉��ꂩ
 * @param {String} link	�����N��B�Ƃ肠����"#"��OK�B
 * @param {String} str	�{�^���ɋL�q���镶����B
 */
function createButton(x, link, str) {
	var a = $("<a/>").attr("href", link).addClass("button" + x + "x30");
	a.append($("<span/>").addClass("btnChild").html(str));
	return a;
}

/**
 * �I����Ԃ̃{�^���摜���쐬����B
 *
 * @since 2009/1/14
 * @param {int} x	x�T�C�Y�B30/60/90/180�̉��ꂩ
 * @param {String} str	�{�^���ɋL�q���镶����B
 */
function acreateButtonSelect(x, str) {
	var div = $("<div/>").addClass("button" + x + "x30On");
	div.append($("<span/>").addClass("btnChild").html(str));
	return div;
}


/**
 * �}�E�X�I�[�o�[�ŉ摜�������ւ���input�^�O�𐶐�����B
 *
 * @param {String} srcOver
 * @param {String} srcOn
 */
function createSwapInput(srcOn, srcOver) {
	var imgOn = $("<img/>").attr("src", srcOn).css("display", "none");
	var imgOver = $("<img/>").attr("src", srcOver).css("display", "none");
	var input = $("<input type=\"image\" />").attr("src", srcOn).attr("alt", name);
	// �}�E�X�I�[�o�[�ŉ摜�����ւ�
	input.hover(function() {
		input.attr("src", imgOver.attr("src"));
	}, function() {
		input.attr("src", imgOn.attr("src"));
	});
	// �u���E�U�ɃL���b�V�������邽�߁Abody�ɔ�\����img�^�O��ǉ��B
	$().append(imgOn).append(imgOver);
	return input;
}


/**
 * "/goform/formMainZone_MainZoneXml.xml" ���p�[�X����html���\�z����BPower�����{TopMenu�����N
 *
 * @since	2009/1/7
 * @param {XMLDocument} data ./index.html.xml.asp �̓ǂݍ��݌���
 */
function parsePowerXml(data) {
	//===========

	// TopMenu
	if (data.getValue("TopMenuLink").toUpperCase() == "ON") {
		$("div#TopMenu").css("visibility", "visible");
	} else {
		$("div#TopMenu").css("visibility", "hidden");
	}

	//Friendly Name
	$("h2").html(data.getValue("FriendlyName"));

	//===========
	// ZonePower
	if (data.getValue("ZonePower") == "ON") {
		$("div#powerBtn div.RPowerBtn").empty().append(createSwapInput("../img/Power_On.png", "../img/Power_On_MO.png").click(function() {
			putRequest({
				cmd0: "PutZone_OnOff/OFF",
				cmd1: "aspMainZone_WebUpdateStatus/"
			}, true, true);
			return false;
		}));
	} else {
		$("div#powerBtn div.RPowerBtn").empty().append(createSwapInput("../img/Power_OFF.png", "../img/Power_OFF_MO.png").click(function() {
			putRequest({
				cmd0: "PutZone_OnOff/ON",
				cmd1: "aspMainZone_WebUpdateStatus/"
			}, true, true);
			return false;
		}));
	}

	//===========
	// RenameZone
	$("div.RParamZoneName").html(data.getValue("RenameZone"));


	// Sleep Timer
	var ListTimer = $( "div#SleepTimer select" ).empty();

	var opt = $( "<option/>" );
	opt.html( "" ).attr( "value", "" );
	ListTimer.append( opt );

	var opt = $( "<option/>" );
	opt.html( "OFF" ).attr( "value", "OFF" );
	ListTimer.append( opt );

	for( var cnt=1; cnt<=12; cnt+=1 ) {
		var opt = $( "<option/>" );
		var timer = cnt*10;
		if(timer<10){
			opt.html( timer ).attr( "value", ("00" + timer) );
		}else if(timer<100){
			opt.html( timer ).attr( "value", ("0" + timer) );
		}else{
			opt.html( timer ).attr( "value", timer );
		}
		ListTimer.append( opt );
	}
}

/**
 * "/goform/formMainZone_MainZoneXml.xml" ���p�[�X����html���\�z����BSource����
 *
 * @since	2009/1/7
 * @param {XMLDocument} data ./index.html.xml.asp �̓ǂݍ��݌���
 */
function parseFuncXml(data) {
	var selectSource = data.getValue("InputFuncSelect");
	var rename = data.find("RenameSource value");
	var source = data.find("InputFuncList value");

	//Source Area
	if((parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5) || // EnModelAVR23XX
	   (parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelNR16XX
	   (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
	   (parseInt( data.getValue( "ModelId" ) ) == 9)) { // EnModelSR60XX
		$("div#funcArea3Cols").css("display", "block");
		$("div#funcArea4Cols").css("display", "none");
	}else{
		$("div#funcArea3Cols").css("display", "none");
		$("div#funcArea4Cols").css("display", "block");
	}

	
	//  Source Name
	$("#source .RParamSource").html(selectSource);

/*
	// source�����p�֐���o�^�B
	source.each(function(index) {
		try {
			source["src" + this.firstChild.nodeValue] = index;
		} catch (e) {
		}
	});
	source.searchSrc = function(src) {
		if (!isNaN(source["src" + src])) {
			return source["src" + src];
		}
		return -1;
	}
	//===========
	//  Source�e�L�X�g

	try {
		$("#source .RParamSource").html(rename[source.searchSrc(selectSource)].firstChild.nodeValue.trim());
	} catch (e) {
		$("#source .RParamSource").html(selectSource);
	}

	//===========
	//  Source�A�C�R���̒ǉ�
	$("div#funcL1 div.RParamRBtnSource3Col1").empty().append(createSwapInput("../img/GAME.png", "../img/GAME.png").click(function() {
		putRequest({
			cmd0: "PutZone_InputFunction/GAME",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));
*/
	//Line1
	appendSource($("div#funcL1 div.RParamRBtnSource3Col1"), "../img/Func_CBLSAT.png",		"../img/Func_CBLSAT_MO.png", 	"SAT/CBL");
	appendSource($("div#funcL1 div.RParamRBtnSource3Col2"), "../img/Func_DVD.png", 			"../img/Func_DVD_MO.png", 		"DVD");
	appendSource($("div#funcL1 div.RParamRBtnSource3Col3"), "../img/Func_BLURAY.png", 		"../img/Func_BLURAY_MO.png", 	"BD");

	//Line2
	appendSource($("div#funcL2 div.RParamRBtnSource3Col1"), "../img/Func_GAME.png", 		"../img/Func_GAME_MO.png", 		"GAME");
	appendSource($("div#funcL2 div.RParamRBtnSource3Col2"), "../img/Func_AUX.png", 			"../img/Func_AUX_MO.png", 		"AUX1");
	appendSource($("div#funcL2 div.RParamRBtnSource3Col3"), "../img/Func_MEDIAPLAYER.png", 	"../img/Func_MEDIAPLAYER_MO.png", "MPLAY");

	//Line3
	if((parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5)){ // EnModelAVR23XX
		appendSource($("div#funcL3 div.RParamRBtnSource3Col1"), "../img/Func_IPODUSB.png", 	"../img/Func_IPODUSB_MO.png", "USB/IPOD");
	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelNR16XX
			 (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
			 (parseInt( data.getValue( "ModelId" ) ) == 9)) { // EnModelSR60XX
		appendSource($("div#funcL3 div.RParamRBtnSource3Col1"), "../img/Func_TVAUDIO.png", 	"../img/Func_TVAUDIO_MO.png", "TV");
	}

	if(parseInt( data.getValue( "ModelId" ) ) == 2){			// EnModelAVR17XX
		appendSource($("div#funcL3 div.RParamRBtnSource3Col2"), "../img/Func_TVAUDIO.png", 	"../img/Func_TVAUDIO_MO.png", "TV");
	}else{
		appendSource($("div#funcL3 div.RParamRBtnSource3Col2"), "../img/Func_CD.png", 		"../img/Func_CD_MO.png", "CD");
	}
	appendSource($("div#funcL3 div.RParamRBtnSource3Col3"), "../img/Func_FM.png",			"../img/Func_FM_MO.png", "TUNER");

	//Line4
	if((parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5)){ // EnModelAVR23XX
//		appendSource($("div#funcL4 div.RParamRBtnSource3Col1"), "../img/Func_NETWORK.png",	"../img/Func_NETWORK_MO.png", "NET");
		appendSource($("div#funcL4 div.RParamRBtnSource3Col1"), "../img/Func_NETWORK.png",	"../img/Func_NETWORK_MO.png", "NETHOME");
	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelAVR17XX
			 (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
			 (parseInt( data.getValue( "ModelId" ) ) == 9)) { // EnModelSR60XX
		appendSource($("div#funcL4 div.RParamRBtnSource3Col1"), "../img/Func_IPODUSB.png", 	"../img/Func_IPODUSB_MO.png", "USB/IPOD");
	}

	if(parseInt( data.getValue( "ModelId" ) ) == 2){			// EnModelAVR17XX
//		NOP
	}else if((parseInt( data.getValue( "ModelId" ) ) == 3) ||	// EnModelAVR19XX
			 (parseInt( data.getValue( "ModelId" ) ) == 4) || 	// EnModelAVR21XX
			 (parseInt( data.getValue( "ModelId" ) ) == 5)) { 	// EnModelAVR23XX
		appendSource($("div#funcL4 div.RParamRBtnSource3Col2"), "../img/Func_TVAUDIO.png", 	"../img/Func_TVAUDIO_MO.png", 	"TV");
	}else if(parseInt( data.getValue( "ModelId" ) ) == 9) { 	// EnModelSR60XX
		appendSource($("div#funcL4 div.RParamRBtnSource3Col2"), "../img/Func_PHONO.png", 	"../img/Func_PHONO_MO.png", 	"PHONO");
	}

	if((parseInt( data.getValue( "ModelId" ) ) == 2)	   ||	// EnModelAVR17XX
			 (parseInt( data.getValue( "ModelId" ) ) == 3) || 	// EnModelAVR19XX
			 (parseInt( data.getValue( "ModelId" ) ) == 4) || 	// EnModelAVR21XX
			 (parseInt( data.getValue( "ModelId" ) ) == 5)) { 	// EnModelAVR23XX
		appendSource($("div#funcL4 div.RParamRBtnSource3Col3"), "../img/Func_INTERNETRADIO.png","../img/Func_INTERNETRADIO_MO.png","IRADIO");
	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) ||	// EnModelNR16XX
			 (parseInt( data.getValue( "ModelId" ) ) == 8) || 	// EnModelSR50XX
			 (parseInt( data.getValue( "ModelId" ) ) == 9)) { 	// EnModelSR60XX
		appendSource($("div#funcL4 div.RParamRBtnSource3Col3"), "../img/Func_MXPORT.png","../img/Func_MXPORT_MO.png","M-XPORT");
	}

	//Line5
	if((parseInt( data.getValue( "ModelId" ) ) == 7) ||	// EnModelNR16XX
	   (parseInt( data.getValue( "ModelId" ) ) == 8) || 	// EnModelSR50XX
	   (parseInt( data.getValue( "ModelId" ) ) == 9)) { 	// EnModelSR60XX
//		appendSource($("div#funcL5 div.RParamRBtnSource3Col1"), "../img/Func_NETWORK.png",		 "../img/Func_NETWORK_MO.png", 		"NET");
		appendSource($("div#funcL5 div.RParamRBtnSource3Col1"), "../img/Func_NETWORK.png",		 "../img/Func_NETWORK_MO.png", 		"NETHOME");
		appendSource($("div#funcL5 div.RParamRBtnSource3Col2"), "../img/Func_INTERNETRADIO.png", "../img/Func_INTERNETRADIO_MO.png", "IRADIO");
	}

	//Line6(Favorite Station)
	$("div#funcL6 div,RParamFavoriteStation").css("display", "block");

	appendSource($("div#funcL6 div.RParamRBtnSource3Col1"), "../img/Fav_S1.png","../img/Fav_S1_MO.png", "FAVORITE1");
	appendSource($("div#funcL6 div.RParamRBtnSource3Col2"), "../img/Fav_S2.png","../img/Fav_S2_MO.png", "FAVORITE2");
	appendSource($("div#funcL6 div.RParamRBtnSource3Col3"), "../img/Fav_S3.png","../img/Fav_S3_MO.png", "FAVORITE3");

	//  Source�A�C�R���̒ǉ�
/*
	$("div#funcL1 div.RParamRBtnSource4Col1").empty().append(createSwapInput("../img/CBLSAT.png", "../img/CBLSAT.png").click(function() {
		putRequest({
			cmd0: "PutZone_InputFunction/CBL/SAT",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));
*/
	//Line1
	appendSource($("div#funcL1 div.RParamRBtnSource4Col1"), "../img/Func_CBLSAT.png",	"../img/Func_CBLSAT_MO.png",	"SAT/CBL");
	appendSource($("div#funcL1 div.RParamRBtnSource4Col2"), "../img/Func_DVD.png",		"../img/Func_DVD_MO.png",		"DVD");
	appendSource($("div#funcL1 div.RParamRBtnSource4Col3"), "../img/Func_GAME.png",		"../img/Func_GAME_MO.png",		"GAME");
	appendSource($("div#funcL1 div.RParamRBtnSource4Col4"), "../img/Func_BLURAY.png",	"../img/Func_BLURAY_MO.png",	"BD");

	//Line2
	appendSource($("div#funcL2 div.RParamRBtnSource4Col1"), "../img/Func_AUX1.png",		"../img/Func_AUX1_MO.png",		"AUX1");
	appendSource($("div#funcL2 div.RParamRBtnSource4Col2"), "../img/Func_AUX2.png",		"../img/Func_AUX2_MO.png",		"AUX2");
	appendSource($("div#funcL2 div.RParamRBtnSource4Col3"), "../img/Func_MEDIAPLAYER.png",	"../img/Func_MEDIAPLAYER_MO.png","MPLAY");
	appendSource($("div#funcL2 div.RParamRBtnSource4Col4"), "../img/Func_TVAUDIO.png",	"../img/Func_TVAUDIO_MO.png",	"TV");

	//Line3
	if (data.getValue("SalesArea") == "0") {	// USA
		appendSource($("div#funcL3 div.RParamRBtnSource4Col1"), "../img/Func_HDRADIO.png",	"../img/Func_HDRADIO_MO.png", 	"HDRADIO");
	}else{
		appendSource($("div#funcL3 div.RParamRBtnSource4Col1"), "../img/Func_FM.png",	"../img/Func_FM_MO.png", 		"TUNER");
	}

	appendSource($("div#funcL3 div.RParamRBtnSource4Col2"), "../img/Func_CD.png",		"../img/Func_CD_MO.png",	"CD");
	appendSource($("div#funcL3 div.RParamRBtnSource4Col3"), "../img/Func_PHONO.png",	"../img/Func_PHONO_MO.png",	"PHONO");
	appendSource($("div#funcL3 div.RParamRBtnSource4Col4"), "../img/Func_INTERNETRADIO.png","../img/Func_INTERNETRADIO_MO.png","IRADIO");

	//Line4
//	appendSource($("div#funcL4 div.RParamRBtnSource4Col1"), "../img/Func_NETWORK.png",	"../img/Func_NETWORK_MO.png","NET");
	appendSource($("div#funcL4 div.RParamRBtnSource4Col1"), "../img/Func_NETWORK.png",	"../img/Func_NETWORK_MO.png","NETHOME");
	appendSource($("div#funcL4 div.RParamRBtnSource4Col2"), "../img/Func_IPODUSB.png",	"../img/Func_IPODUSB_MO.png","USB/IPOD");
	if((parseInt( data.getValue( "ModelId" ) ) == 10) ||	// EnModelSR70XX
	   (parseInt( data.getValue( "ModelId" ) ) == 12) || 	// EnModelAV7701
	   (parseInt( data.getValue( "ModelId" ) ) == 13)) { 	// EnModelAV8801
		appendSource($("div#funcL4 div.RParamRBtnSource4Col3"), "../img/Func_MXPORT.png","../img/Func_MXPORT_MO.png","M-XPORT");
	}

	//Line5(Favorite Station)
	$("div#funcL5 div.RParamFavoriteStation").css("display", "block");
	appendSource($("div#funcL5 div.RParamRBtnSource4Col1"), "../img/Fav_S1.png","../img/Fav_S1_MO.png", "FAVORITE1");
	appendSource($("div#funcL5 div.RParamRBtnSource4Col2"), "../img/Fav_S2.png","../img/Fav_S2_MO.png", "FAVORITE2");
	appendSource($("div#funcL5 div.RParamRBtnSource4Col3"), "../img/Fav_S3.png","../img/Fav_S3_MO.png", "FAVORITE3");
	appendSource($("div#funcL5 div.RParamRBtnSource4Col4"), "../img/Fav_S4.png","../img/Fav_S4_MO.png", "FAVORITE4");


	if((parseInt( data.getValue( "ModelId" ) ) == 1) || // EnModelAVR16XX
	   (parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5) || // EnModelAVR23XX
	   (parseInt( data.getValue( "ModelId" ) ) == 11) || // EnModelAVR45XX
	   (parseInt( data.getValue( "ModelId" ) ) == 6)) { // EnModelAVR33XX

		$("div#left").css("background-color", "#0e1033");

	   	//LOGO
		$("div#menuItemLogo").html("<img src= ../img/denon_Logo.gif>");

		//Quick Select
		$("div#QuickSelect").css("visibility", "visible");
	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelNR16XX
	   		 (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
	         (parseInt( data.getValue( "ModelId" ) ) == 9) || // EnModelSR60XX
	         
	   		 (parseInt( data.getValue( "ModelId" ) ) == 12) || // EnModelAV7701
	         (parseInt( data.getValue( "ModelId" ) ) == 13) || // EnModelAV8801
	         
	         (parseInt( data.getValue( "ModelId" ) ) == 10)) { // EnModelSR70XX

	   $("div#left").css("background-color", "#b3b3b3");

		//LOGO
		$("div#menuItemLogo").html("<img src= ../img/marantz_Logo.png>");

		//Quick Select
		$("div#QuickSelect").css("visibility", "hidden");
	}

	//LINK

	//FM/HD Radio
	if((parseInt( data.getValue( "ModelId" ) ) == 6) || // EnModelAVR33XX
	   (parseInt( data.getValue( "ModelId" ) ) == 11) || // EnModelAVR45XX
	   (parseInt( data.getValue( "ModelId" ) ) == 12) || // EnModelAV7701
	   (parseInt( data.getValue( "ModelId" ) ) == 13) || // EnModelAVR33XX
	   (parseInt( data.getValue( "ModelId" ) ) == 10)) { // EnModelAV8801
		if (data.getValue("SalesArea") == "0") {	// USA
			$("div#FM").css("display", "none");
			$("div#HDRADIO").css("display", "block");
		}else{
			$("div#FM").css("display", "block");
			$("div#HDRADIO").css("display", "none");
		}
	}else{
		$("div#FM").css("display", "block");
		$("div#HDRADIO").css("display", "none");
	}

	//===========
	// NETWORK LINK
	$( "div#NETWORK" ).css( "visibility", "visible" ).find( "a" ).unbind("click").click( function( event ) {
		$.ajax({
			url: "/MainZone/index.put.asp",
			data: {
				cmd0: "PutZone_InputFunction/NET",
				cmd1: "aspMainZone_WebUpdateStatus/",
				ZoneName: $.cookie( "ZoneName" )
			},
			type: "POST",
			bFill: true,
			async: false
		} );
	});

	//===========
	// iPod/USB LINK
	$( "div#iPodUSB" ).css( "visibility", "visible" ).find( "a" ).unbind("click").click( function( event ) {
		$.ajax({
			url: "/MainZone/index.put.asp",
			data: {
				cmd0: "PutZone_InputFunction/USB/IPOD",
				cmd1: "aspMainZone_WebUpdateStatus/",
				ZoneName: $.cookie( "ZoneName" )
			},
			type: "POST",
			bFill: true,
			async: false
		} );
	});

	//===========
	// FM LINK
	$( "div#FM" ).css( "visibility", "visible" ).find( "a" ).unbind("click").click( function( event ) {
		$.ajax({
			url: "/MainZone/index.put.asp",
			data: {
				cmd0: "PutZone_InputFunction/TUNER",
				cmd1: "aspMainZone_WebUpdateStatus/",
				ZoneName: $.cookie( "ZoneName" )
			},
			type: "POST",
			bFill: true,
			async: false
		} );
	});

	//===========
	// HD Radio LINK
	$( "div#HDRADIO" ).css( "visibility", "visible" ).find( "a" ).unbind("click").click( function( event ) {
		$.ajax({
			url: "/MainZone/index.put.asp",
			data: {
				cmd0: "PutZone_InputFunction/HDRADIO",
				cmd1: "aspMainZone_WebUpdateStatus/",
				ZoneName: $.cookie( "ZoneName" )
			},
			type: "POST",
			bFill: true,
			async: false
		} );
	});



}

/**
 * "/goform/formMainZone_MainZoneXml.xml" ���p�[�X����html���\�z����BSurround����
 *
 * @since	2011/11/23
 * @param {XMLDocument} data ./index.html.xml.asp �̓ǂݍ��݌���
 */

function parseSurroundXml(data) {

	//Sound Area
	if((parseInt( data.getValue( "ModelId" ) ) == 1) || // EnModelAVR16XX
	   (parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5) || // EnModelAVR23XX
	   (parseInt( data.getValue( "ModelId" ) ) == 11) || // EnModelAVR45XX
	   (parseInt( data.getValue( "ModelId" ) ) == 6)) { // EnModelAVR33XX

		$("div#SurroundCallDE").css("display", "block");
		$("div#SurroundCallMZ").css("display", "none");

	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelNR16XX
	   		 (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
	         (parseInt( data.getValue( "ModelId" ) ) == 9) || // EnModelSR60XX
	         
	   		 (parseInt( data.getValue( "ModelId" ) ) == 12) || // EnModelAV7701
	         (parseInt( data.getValue( "ModelId" ) ) == 13) || // EnModelAV8801
	         
	         (parseInt( data.getValue( "ModelId" ) ) == 10)) { // EnModelSR70XX

		$("div#SurroundCallDE").css("display", "none");
		$("div#SurroundCallMZ").css("display", "block");
	}

	var selectSurround = data.getValue("selectSurround");

	//Surround Mode
	$("div#Surround div.RParamSource").html(selectSurround);

	$("div#SurroundBottom div.RParamRBtnSurrMovie").empty().append(createSwapInput("../img/Surr_MOVIE.png", "../img/Surr_MOVIE_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/MOVIE",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottom div.RParamRBtnSurrMusic").empty().append(createSwapInput("../img/Surr_MUSIC.png", "../img/Surr_MUSIC_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/MUSIC",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottom div.RParamRBtnSurrGame").empty().append(createSwapInput("../img/Surr_GAME.png", "../img/Surr_GAME_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/GAME",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottom div.RParamRBtnSurrPure").empty().append(createSwapInput("../img/Surr_PURE.png", "../img/Surr_PURE_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/PURE DIRECT",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));
	
	
	$("div#SurroundBottomDE div.RParamRBtnSound4Col1").empty().append(createSwapInput("../img/Surr_DIRECT.png", "../img/Surr_DIRECT_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/DIRECT",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottomDE div.RParamRBtnSound4Col2").empty().append(createSwapInput("../img/Surr_STEREO.png", "../img/Surr_STEREO_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/STEREO",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottomDE div.RParamRBtnSound4Col3").empty().append(createSwapInput("../img/Surr_STANDARD.png", "../img/Surr_STANDARD_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/STANDARD",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottomDE div.RParamRBtnSound4Col4").empty().append(createSwapInput("../img/Surr_SIMULATION.png", "../img/Surr_SIMULATION_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/SIMULATION",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));


	$("div#SurroundBottomMZ div.RParamRBtnSound3Col1").empty().append(createSwapInput("../img/Surr_AUTO.png", "../img/Surr_AUTO_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/AUTO",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottomMZ div.RParamRBtnSound3Col2").empty().append(createSwapInput("../img/Surr_SURROUND.png", "../img/Surr_SURROUND_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/LEFT",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	$("div#SurroundBottomMZ div.RParamRBtnSound3Col3").empty().append(createSwapInput("../img/Surr_STEREO.png", "../img/Surr_STEREO_MO.png").click(function() {
		putRequest({
			cmd0: "PutSurroundMode/STEREO",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	
}


/**
 * "/goform/formMainZone_MainZoneXml.xml" ���p�[�X����html���\�z����BVolume����
 *
 * @since	2009/1/7
 * @param {XMLDocument} data ./index.html.xml.asp �̓ǂݍ��݌���
 */
function parseVolumeXml(data) {
	var bar;
	var bMute = data.getValue("Mute") != "off";
	
	var VolumeColor;
	var MuteOffIcon;
	
	if((parseInt( data.getValue( "ModelId" ) ) == 1) || // EnModelAVR16XX
	   (parseInt( data.getValue( "ModelId" ) ) == 2) || // EnModelAVR17XX
	   (parseInt( data.getValue( "ModelId" ) ) == 3) || // EnModelAVR19XX
	   (parseInt( data.getValue( "ModelId" ) ) == 4) || // EnModelAVR21XX
	   (parseInt( data.getValue( "ModelId" ) ) == 5) || // EnModelAVR23XX
	   
	   (parseInt( data.getValue( "ModelId" ) ) == 11) || // EnModelAVR45XX
	   
	   (parseInt( data.getValue( "ModelId" ) ) == 6)) { // EnModelAVR33XX
		VolumeColor	= "#88BBEE";
		MuteOffIcon = "../img/MuteOff.gif";
	}else if((parseInt( data.getValue( "ModelId" ) ) == 7) || // EnModelNR16XX
	   		 (parseInt( data.getValue( "ModelId" ) ) == 8) || // EnModelSR50XX
	         (parseInt( data.getValue( "ModelId" ) ) == 9) || // EnModelSR60XX
	         
	   		 (parseInt( data.getValue( "ModelId" ) ) == 12) || // EnModelAV7701
	         (parseInt( data.getValue( "ModelId" ) ) == 13) || // EnModelAV8801

	         (parseInt( data.getValue( "ModelId" ) ) == 10)) { // EnModelSR70XX
		VolumeColor	= "#8A6F4C";
		MuteOffIcon = "../img/MuteOff_MZ.gif";
	}

	
	bar = $("div#volumeBar").empty().html($("<input type=\"image\"/>").attr("src", "../img/Volume.gif"));
	
// 0-99�\��
//	if ( !data.isAbsolute() ) {
//		bar = $("div#volumeBar").empty().html($("<input type=\"image\"/>").attr("src", "../img/Volume.gif"));
// dB�\��
//	} else {
//		bar = $("div#volumeBar").empty().html($("<input type=\"image\"/>").attr("src", "../img/Volume2.gif"));
//	}

	// Volume
//	var text = $("div#volumeText").html(data.getVolume()).css("font-weight", "bolder");
	if (bMute) {
		var text = $("div#volumeText").html("MUTING ON");
		text.css("color", "gray");
	} else {
		var text = $("div#volumeText").html(data.getVolume()).css("font-weight", "bolder");
//		text.css("color", "#FFFF00");
//		text.css("color", "#88BBEE");
		text.css("color", VolumeColor);
	}

	//[<]
	$("div#volumeDown").empty().append(createSwapInput("../img/btn_Left.png", "../img/btn_Left_MO.png").click(function() {
		putRequest({
			cmd0: "PutMasterVolumeBtn/<",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	//[>]
	$("div#volumeUp").empty().append(createSwapInput("../img/btn_Right.png", "../img/btn_Right_MO.png").click(function() {
		putRequest({
			cmd0: "PutMasterVolumeBtn/>",
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));

	//Mute
	if (bMute) {
//		$("div#volumeMute").empty().append(createSwapInput("../img/MuteOff.gif", "../img/MuteOn.gif").click(function() {
		$("div#volumeMute").empty().append(createSwapInput(MuteOffIcon, "../img/MuteOn.gif").click(function() {		
			putRequest({
				cmd0: "PutVolumeMute/" + "off",
				cmd1: "aspMainZone_WebUpdateStatus/"
			}, true, true);
		}));
	} else {
//		$("div#volumeMute").empty().append(createSwapInput("../img/MuteOff.gif", "../img/MuteOn.gif").click(function() {
		$("div#volumeMute").empty().append(createSwapInput(MuteOffIcon, "../img/MuteOn.gif").click(function() {		
			putRequest({
				cmd0: "PutVolumeMute/" + "on",
				cmd1: "aspMainZone_WebUpdateStatus/"
			}, true, true);
		}));
	}

	var volBar = bar.find("input");
	volBar.convdB = function(event) { // �}�E�X�ʒu��dB�ɕϊ�����
		var w = $(this).width();

		//IE/Safari/Chrome/Opera
		var x2 = event.offsetX;
		//Mozilla
		var x3 = event.layerX-200;

		if(isNaN(x2)){
			x=x3;
		}else{
			x=x2;
		}

//		var vol = parseInt(99 * x / w);
		var vol = 99 * x / w;
		// �኱�摜�ƍ��ق����邽�ߕ␳�B-80.5-3�`18.0+4�͈̔͂ɂ���B
		vol = vol / 100 * 110 - 87.5;
		if (vol > 18.0) {
			vol = 18.0;
		} else {
			// 1.0dB���݂ɕ␳
			vol = parseInt(vol);
		}
		if (vol < -80.5 ) {
			return "--";
		}
		// �����Ȃ�".0"��������
		if (vol * 2 % 2 == 0) {
			return vol + ".0";
		}
		return vol.toString();
	}

	volBar.click(function(event) {
		volBar.bSend = true;
		putRequest({
			cmd0: "PutMasterVolumeSet/" + volBar.convdB(event)
		}, true, true);
	});
	volBar.mousemove(function(event) {
		text.html(data.getVolume(volBar.convdB(event))).css("color", "Silver").css("font-weight", "normal");
	});
	volBar.mouseout(function() {
		if (volBar.bSend) {
			return;
		}
		text.html(data.getVolume()).css("font-weight", "bolder");
		if (bMute) {
			text.css("color", "gray");
		} else {
//			text.css("color", "#FFFF00");
//		text.css("color", "#88BBEE");
		text.css("color", VolumeColor);
		}
	});
}



/**
 *
 * @param {Object} obj		Object
 * @param {String} imgOn	Normal Image
 * @param {String} imgOver	Mouse Over Image
 * @param {String} cmd		SI command Option
**/

//function appendSource(obj, del, source, rename, values, select, bNet) {
function appendSource(obj, imgOn, imgOver, cmd) {
	// ��x��ɂ��Ă���ǉ�����B
	obj.empty();

	$(obj).empty().append(createSwapInput(imgOn, imgOver).click(function() {
		putRequest({
			cmd0: "PutZone_InputFunction/" + cmd,
			cmd1: "aspMainZone_WebUpdateStatus/"
		}, true, true);
	}));
}

/**
 * ./index.put.asp ��data�𑗐M����B
 *
 * @since	2009/01/09
 * @param {Object} data
 * @param {Object} bReload
 * @param {Object} bFill
 */
function putRequest(data, bReload, bFill) {
	var url = "";
	if (_bDebug) {
		url = "/proxy.php?url=" + encodeURI("MainZone/index.put.asp");
		//url = "/postVar.php";
	} else {
		url = "./index.put.asp";
	}
	$.post(url, data, function(data) {
		if (_bDebug) {
			//alert(data);
		}
		if (bReload) {
			loadMainXml(bFill);
			setTimeout( function() {
				loadMainXml( false );
			}, 2000 );
		}
	});
}

// �v���O�����J�n�B
appStart();
