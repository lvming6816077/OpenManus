const CryptoJS = require('crypto-js');
const axios = require('axios');


const cryptoValue = "vss7db748e839799";
const CAKEY = "ngari-wx";
const CASECRET = "a9d4eb7841b1ba47";

// 加密函数
function encrypt(data) {
    data = JSON.stringify(data);
    var cipher = CryptoJS.AES.encrypt(data, CryptoJS.enc.Utf8.parse(cryptoValue), {
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7,
        iv: ""
    });
    return cipher.ciphertext.toString(CryptoJS.enc.Base64)
}

// 解密函数
function decrypt(base64Cipher) {
    var decipher = CryptoJS.AES.decrypt(base64Cipher, CryptoJS.enc.Utf8.parse(cryptoValue), {
        mode: CryptoJS.mode.ECB,
        padding: CryptoJS.pad.Pkcs7,
        iv: ""
    });
    return CryptoJS.enc.Utf8.stringify(decipher)
}
var getMd5 = function(data) {
    var md5 = CryptoJS.MD5(data);
    return md5.toString(CryptoJS.enc.Base64)
};
var getUuid = function() {
    var uuid;
    var _randomKey = 1;
    var str = "xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx".replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0
          , v = c == "x" ? r : r & 3 | 8;
        return v.toString(16) + ++_randomKey
    });
    uuid = str.substring(str.length - 45)
    return uuid
};
var getSecureHeader = function(jsonData) {
    return {
        "X-Ca-Key": CAKEY,
        "X-Ca-Nonce": getUuid(),
        "X-Ca-Timestamp": +new Date,
        "X-Content-MD5": getMd5(jsonData),
        "X-Service-Encrypt":'1'
    }
};
var getSignHeader = function(headers) {
    var textToSign = "";
    var headerArr = ["X-Ca-Key", "X-Ca-Nonce", "X-Ca-Timestamp", "X-Content-MD5", "X-Service-Id", "X-Service-Method"];
    for (var i = 0; i < headerArr.length; i++) {
        var it = headerArr[i];
        var name = it.toLowerCase();
        var value = headers[it];
        textToSign += name + ":" + value + "&"
    }
    textToSign = textToSign.substring(0, textToSign.length - 1);
    var hash = CryptoJS.HmacSHA256(textToSign, CASECRET);
    var signature = hash.toString(CryptoJS.enc.Base64);
    return signature
};

const fetchData = (op,token)=>{

	let jsonData = encrypt(op)
	var secureHeader = getSecureHeader(JSON.stringify(jsonData));
	let headers = {
	    'Content-Type': 'application/json', // 设置请求头
	    // 'Cookie': cookie, // 自定义请求头
		'X-Access-Token': token,
		'X-Client-Id': '110614067',

	    'X-Service-Id': 'appoint.requestAppointRecordService',
	    'X-Service-Method': 'addAppointRecord',
	    'X-Client-Source': 'eh.wx.health.doctor.AppointApply',
	    // 'X-Entrance': 'WX@ngari-health@wxf011d4f784d01944',
	    ...secureHeader
	}

	headers['X-Ca-Signature'] = getSignHeader(headers)


	axios.post('https://weixin.ngarihealth.com/weixin/wx/mp/wxf011d4f784d01944/gateway', jsonData, {
	    headers: headers
	})
	.then(response => {
		console.log(op[0].orderNum)
	    console.log('Response:', decrypt(response.data));
	})
	.catch(error => {
	    console.error('Error:', error.message);
	});
}

// // const decrypted = decrypt('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')
const decrypted = decrypt('Naj/jVHKKe98Yf8g2yevgPF7+0UYSzhfR+vb7DlGyABOD99MY+c1c95VtPiBTpXorrU1dZoo+sR/5gAhoIY52jVP1HYDOV1GIjHUpmCaZTMm2lFxj6e1hfMd441ynV59MBQrUv2PqsfsVxbwJIGTlktU8YqOrTDKzGWOk1nHT1Mh5L7NsbyNxpkwODbTY7+0xU5BencPSKALQJBfGHFUBfaysKLk8CxKeXepMoKtie03c8VS1PRLFoSHNj9mQZt0po/UP0frzz+OOqNfhNeomRpK8lfW8gDmLsiC1caM+OS3A4sTkhJk/CMYcxXBMFI1yG/qWyt9j73eEjtyln2OIQ1A4jf812bFNVPXtI7hgIpja+hFWM9SnKmjpy5iJMg+1dwGgp5OFDyF5wTc/cCRndYS9yuQwirpqrgNcMX60H6WCCMnNloQHT3mEiezQuJw01ILgYxLE20/Spw371M7/w/SopJWqVFsOckUPflBGn3uO9K6SdAsygXQBdtPwqSq6uJ+WJxu4sM8Yv/vjQNWSIyFrA4a2CDLgfyrKwPYUYkfMxfaBkLnvIML2nDlkn1K9NDnRTDqFeBBRm5Y0hT7hZLgBvJZJO2Fl66O6zrbpi7Cky7fPpalGDGaRl5Kjn8AMnQ45jMwmzVeMwbQZRoDIQGWKRAS/0ZFaZ4aDcHqmg1qqoY6y2ahCR1DQspWcxKJyqV0g/pgwdkfR46385uJY8a/TREx402IEO9UyIUYlO+N3RQsIj6kfDJdB2jl+ZbQXvycBwF2FPbWJmtc+OVQg1Tm76bYTV7UUGS6Gdhj7sE=')
console.log(decrypted)

return




// let op = [{"loginId":"6405cabd79e7cb4e8ee5c1f7","mpiId":"2c90821f869794890186b69ff61112d6","patientName":"吕鸣","patientSex":"1","birthday":"1990-12-27 00:00:00","patientType":"1","mobile":"185****6487","address":"******","homeArea":"410105","createDate":"2023-03-06 19:13:02","lastModify":"2025-03-11 19:49:39","status":1,"guardianFlag":false,"certificate":"4****************4","certificateType":1,"fullHomeArea":"河南省 郑州市 金水区","patientUserType":0,"authStatus":0,"isOwn":true,"healthCards":[{"healthCardId":332688172,"mpiId":"2c90821f869794890186b69ff61112d6","cardId":"4101**********0074","cardType":"1","cardOrgan":1004211,"cardStatus":1,"initialCardID":"4101**********0074","cardSource":"remote","createDate":"2025-03-11 19:49:41","defaultCard":true,"healthCardName":"门诊自费","cardBalance":"0.0000","showFlag":true,"patId":"473733","cardPayType":"","cardOrganText":"河南省中西医结合医院","cardTypeText":"就诊卡"}],"loginName":"185****6487","userName":"吕 鸣","urt":79397390,"userIcon":"","guardianCertificateType":1,"ageString":"34岁","guardianCertificateTypeText":"身份证","patientSexText":"男","patientTypeText":"自费","homeAreaText":"金水区","marryText":"","jobText":"","nationText":"","countryText":"","stateText":"","birthPlaceText":"","authStatusText":"未认证","houseHoldText":"","residentText":"","expectClinicPeriodTypeText":"","patientUserTypeText":"成人","certificateTypeText":"身份证","statusText":"正常","educationText":"","defaultPatient":true,"tempMobileTemp":"185****6487","tempMobile":"185****6487","origCardId":"4101**********0074","tempCardId":"4101**********0074","tempAddress":"******"}]
let token = '322be89c-51bb-46d0-8f35-75e1377227fa'
let op1 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "08:00",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 1,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]
let op2 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "08:16",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 2,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]
let op3 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "08:32",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 3,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]
let op4 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "08:48",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 4,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]
let op5 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "09:04",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 5,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]
let op6 = [{
	"mpiid": "2c90821f869794890186b69ff61112d6",
	"patientName": "吕鸣",
	"organAppointId": "",
	"scheduleId": 146543741,
	"scheduleTimeId": "4",
	"orderNumSopt": "09:20",
	"organId": 1004211,
	"appointDepartId": "0058",
	"appointDepartName": "内科五",
	"doctorId": 107998,
	"workDate": "2025-03-19 00:00:00",
	"workType": 4,
	"startTime": "2025-03-19 08:00:00",
	"endTime": "2025-03-19 12:00:00",
	"orderNum": 6,
	"appointRoad": 5,
	"appointStatus": 0,
	"appointPath": 9,
	"appointUser": "2c90821f869794890186b69ff61112d6",
	"appointName": "吕鸣",
	"appointOragn": "",
	"clinicPrice": 15.5,
	"transferId": 0,
	"sourceLevel": 2,
	"clinicId": "473733",
	"ifCreateFollowPlan": 1,
	"cardId": "410104199012270074",
	"triggerId": null,
	"medInsureCarId": "",
	"appointRecordExt": {
		"illSummaryTxt": "",
		"thirdChannel": null
	},
	"analyzeNvcData": "",
	"ruleString": "",
	"isRealTime": 0,
	"cardType": "1"
}]



// fetchData(op,token)
fetchData(op2,token)
// setTimeout(()=>{
// 	fetchData(op1,token)
// },1300)
// setTimeout(()=>{
// 	fetchData(op3,token)
// },2400)
// setTimeout(()=>{
// 	fetchData(op4,token)
// },3500)
// setTimeout(()=>{
// 	fetchData(op5,token)
// },4700)
// setTimeout(()=>{
// 	fetchData(op6,token)
// },6000)


// fetchData(op5,token)
// fetchData(op6,token)
