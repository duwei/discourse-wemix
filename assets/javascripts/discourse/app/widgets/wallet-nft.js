import { createWidget } from "discourse/widgets/widget";
import { ajax } from "discourse/lib/ajax";
import { h } from "virtual-dom";
import { getOwner } from "discourse-common/lib/get-owner";
import hbs from "discourse/widgets/hbs-compiler";
import { iconNode } from "discourse/helpers/fa-icon-node";
import I18n from "I18n";
import wemixSdk from "../../../lib/wemix-sdk";

export default createWidget('wallet-nft', {
  tagName: 'a',
  buildKey: () => 'wallet-nft',

  defaultState() {
    return { loaded: false };
  },

  html(attrs, state) {
    // return `Click me! ${state.clicks} clicks`;
    return [iconNode('file-invoice-dollar', { title: I18n.t("wallet.nft")})];
  },

  getNftTx() {
    ajax("/wemix/nft/approve_tx", {
      type: "POST",
    }).then((data) => {
      if (data.code === 0) {
        console.log(data);
        // wemixSdk.signMessage(data.message, data.data);
        return ajax("/wemix/nft/approve", {
          type: "POST",
          data: {
            signature: "0xcac62a0dcdc40f761a18873e2ca888c7a4799312a3320f146a650da6ea7be71f47dff53003dd2550bc3c067d6b2c76d67b947b18bc93ea6f3b2c50770fcd6b5a01",
          }
        }).then((data) => {
          if (data.code === 0) {
            console.log(data);
            // wemixSdk.signMessage(data.message, data.data);
          }
        }).finally(() => {
        });
      }
    }).finally(() => {
    });
  },

  mintNftTx() {
    ajax("/wemix/nft/mint_tx", {
      type: "POST",
    }).then((data) => {
      if (data.code === 0) {
        console.log(data);
        // wemixSdk.signMessage(data.message, data.data);
        return ajax("/wemix/nft/mint", {
          type: "POST",
          data: {
            signature: "0xa4ff894e3ad906aa13524af4c9b06311e9bd2228a9fe455018a519712f1164ce2e22926e692a6e9ff247246d0c4e877b91bafc1ffd0b27056e3cf71d690d2e841c",
          }
        }).then((data) => {
          if (data.code === 0) {
            console.log(data);
            // wemixSdk.signMessage(data.message, data.data);
          }
        }).finally(() => {
        });
      }
    }).finally(() => {
    });
  },

  getNftList() {
    ajax("/wemix/nft/list", {
      type: "GET",
    }).then((data) => {
      if (data.code === 0) {
        console.log(data);
      }
    }).finally(() => {
    });
  },

  getNftURI() {
    ajax("/wemix/nft/uri", {
      type: "POST",
      data: {
        token_id: 10
      }
    }).then((data) => {
      if (data.code === 0) {
        console.log(data);
      }
    }).finally(() => {
    });
  },

  click() {
    return this.sendWidgetAction("getNftURI", {});
    return this.sendWidgetAction("getNftTx", {});
    if (wemixSdk.getToken() == null) {
      wemixSdk.auth();
    } else {
      // showModal("test");
      // this.attach("wallet-banner");
      this.sendWidgetAction("getNftTx", {});
    }
  },

  // clickOutside() {
  // }
});
