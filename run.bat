const CryptoJS = require('crypto-js');
const axios = require('axios');
const moment = require('moment');


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

const sendemail = ()=>{
    axios.post('https://report.nihaoshijie.com.cn/rapi/warning/helpMeSendMail',{
	    email:'441403517@qq.com',
	    subject:'qiang',
	    text:'q'
	}).then((res)=>{
		console.log(res)
	})
}
let timer
const fetchData = (op,token,client,mpiid,appointUser)=>{
    op[0].mpiid = mpiid
    op[0].appointUser = appointUser || mpiid

    let jsonData = encrypt(op)
    var secureHeader = getSecureHeader(JSON.stringify(jsonData));
    let headers = {
        'Content-Type': 'application/json', // 设置请求头
        // 'Cookie': cookie, // 自定义请求头
        'X-Access-Token': token,
        'X-Client-Id': client,

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
        let res = JSON.parse(decrypt(response.data))
        console.log(op[0].orderNum + '_Response:', res);
        if (res.code == 200) {
            clearInterval(timer)
            sendemail()
        }

    })
    .catch(error => {
        clearInterval(timer)
        console.error('Error:', error.message);
    });
}

// const d = decrypt('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')
// console.log(d)

// return



let client = '110614067'
let client2 = '202064224'

let mpiid = '2c90821f869794890186b69ff61112d6'
let mpiid2 = '2c908225957f86330195892bb3822799'
// let op = [{"loginId":"6405cabd79e7cb4e8ee5c1f7","mpiId":"2c90821f869794890186b69ff61112d6","patientName":"吕鸣","patientSex":"1","birthday":"1990-12-27 00:00:00","patientType":"1","mobile":"185****6487","address":"******","homeArea":"410105","createDate":"2023-03-06 19:13:02","lastModify":"2025-03-11 19:49:39","status":1,"guardianFlag":false,"certificate":"4****************4","certificateType":1,"fullHomeArea":"河南省 郑州市 金水区","patientUserType":0,"authStatus":0,"isOwn":true,"healthCards":[{"healthCardId":332688172,"mpiId":"2c90821f869794890186b69ff61112d6","cardId":"4101**********0074","cardType":"1","cardOrgan":1004211,"cardStatus":1,"initialCardID":"4101**********0074","cardSource":"remote","createDate":"2025-03-11 19:49:41","defaultCard":true,"healthCardName":"门诊自费","cardBalance":"0.0000","showFlag":true,"patId":"473733","cardPayType":"","cardOrganText":"河南省中西医结合医院","cardTypeText":"就诊卡"}],"loginName":"185****6487","userName":"吕 鸣","urt":79397390,"userIcon":"","guardianCertificateType":1,"ageString":"34岁","guardianCertificateTypeText":"身份证","patientSexText":"男","patientTypeText":"自费","homeAreaText":"金水区","marryText":"","jobText":"","nationText":"","countryText":"","stateText":"","birthPlaceText":"","authStatusText":"未认证","houseHoldText":"","residentText":"","expectClinicPeriodTypeText":"","patientUserTypeText":"成人","certificateTypeText":"身份证","statusText":"正常","educationText":"","defaultPatient":true,"tempMobileTemp":"185****6487","tempMobile":"185****6487","origCardId":"4101**********0074","tempCardId":"4101**********0074","tempAddress":"******"}]
let token = '25d56296-997d-4980-b608-213af09d5197'
let token2 = '94eefeff-c058-4d4c-8a7b-2466b8fb2665'
let op1 = [{
    "mpiid": "2c90821f869794890186b69ff61112d6",
    "patientName": "吕鸣",
    "organAppointId": "",
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "08:00",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "08:16",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "08:32",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "08:48",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "09:04",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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
    "scheduleId": 146783007,
    "scheduleTimeId": "4",
    "orderNumSopt": "09:20",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-20 00:00:00",
    "workType": 4,
    "startTime": "2025-03-20 08:00:00",
    "endTime": "2025-03-20 12:00:00",
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


let current = [{
    "mpiid": "2c90821f869794890186b69ff61112d6",
    "organAppointId": "",
    "scheduleId": 145997047,
    "scheduleTimeId": "4",
    "organId": 1004211,
    "appointDepartId": "0058",
    "appointDepartName": "内科五",
    "doctorId": 107998,
    "workDate": "2025-03-17 00:00:00",
    "workType": 12,
	"startTime": "2025-03-17 08:00:00",
	"endTime": "2025-03-17 12:00:00",
    "orderNum": 0,
    "appointRoad": 5,
    "appointStatus": 0,
    "appointPath": 9,
    "appointUser": "2c90821f869794890186b69ff61112d6",
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






const sendData1 = ()=>{
	fetchData(current,token,client,mpiid)
}
const sendData2 = ()=>{
	fetchData(current,token2,client2,mpiid2,'2c908214957f91e2019587a729921d4a')
}

timer = setInterval(()=>{
    console.log('请求中')
    		sendData1()
    	sendData2()

    

},1200)


// fetchData(op5,token)
// fetchData(op6,token)
