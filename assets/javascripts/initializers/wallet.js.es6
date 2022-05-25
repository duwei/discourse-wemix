import I18n from "I18n";
import { withPluginApi } from "discourse/lib/plugin-api";
const { iconNode } = require("discourse/helpers/fa-icon-node");
const showModal = require("discourse/lib/show-modal").default;
import Mobile from "discourse/lib/mobile";
import getURL from "discourse-common/lib/get-url";
import { createWidget } from 'discourse/widgets/widget';
import { h } from "virtual-dom";

function initializeDetails(api) {

  api.attachWidgetAction('header', "toggleWalletMenu", function() {
    let { state } = this;
    state.walletVisible = !state.walletVisible;
  })

  api.decorateWidget('header-icons:before', function (helper) {
    const siteSettings = api.container.lookup("site-settings:main");
    if (siteSettings.wemix_enabled && api.getCurrentUser()) {
      const headerState = helper.widget.parentWidget.state;

      return [
        helper.attach("header-dropdown", {
          title: "wallet.title",
          icon: "wallet",
          iconId: "wallet-button",
          action: "toggleWalletMenu",
          active: headerState.walletVisible,
          href: getURL("/wallet"),
          classNames: ["wallet-dropdown"],
        }),
        helper.h('li.d-header-icons', helper.h('a.icon.btn-flat', helper.attach("wallet-dollar")))
        // h('li.d-header-icons', h('a.icon.btn-flat', {
        //     attributes: { href: "/dollar", title: I18n.t("wallet.dollar") } },
        //   iconNode('dollar-sign'))
        // )
      ];
    }
  });

  api.addHeaderPanel('wallet-menu', 'walletVisible', function (attrs, state) {
    // console.log(attrs);
  });

  // const showModal = require("discourse/lib/show-modal").default;
  // showModal("test");
}

export default {
  name: "wemix-wallet",
  initialize() {
    withPluginApi("1.2.0", initializeDetails);
  },
};
