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
  }
};
