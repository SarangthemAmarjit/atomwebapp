
function initAES(method, text, key) {
    if (method == 'encrypt') {
        var keyHex = CryptoJS.enc.Utf8.parse(key);
        var encrypted = CryptoJS.AES.encrypt(text, keyHex, {
            mode: CryptoJS.mode.ECB,
            padding: CryptoJS.pad.Pkcs7
        });
        return encrypted.toString();
    } else {
        throw 'Unsupported AES method';
    }

}
