import { ajax } from "discourse/lib/ajax";

let wemix = window.wemix();
const WALLET_DATA = "wallet-data";

export default {
  name: "wemix-sdk",

  getWallet() {
    return sessionStorage.getItem(WALLET_DATA);
  },

  auth(onUpdate){
    wemix.openQR("auth",null,
      success=>{
        wemix.login().then(
          ok => {
            ajax("/wemix/connect", {
              type: "PUT",
              data: {
                wemix_id: ok.data.userID,
                wemix_address: ok.data.address
              }
            }).then((data) => {
              sessionStorage.setItem(WALLET_DATA, ok.data);
              if (onUpdate) {onUpdate(data);}
            }).finally(() => {
            });
          },
          ng => {
            console.log(ng);
          }
        );
      },
      fail=>{
        console.log(fail);
      });
  },

  signMessage(memo, message) {
    let { req } = wemix.requestMessageSignature(memo, "none", message);
    wemix.openQR("sign",req,
      success=>{
        console.log(success);
        const last = success[success.length-1];
        console.log(last);
      },
      fail=>{
        console.log(fail);
        alert("트랜젝션 수행 중 오류가 발생 하였습니다. 개발자 모드의 로그를 확인 바랍니다.");
      });
  }
};
