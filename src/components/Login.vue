<template>
  <div>
    <b-jumbotron header="Cognito" lead="Testing the OAuth2 flow with Cognito">
      <div class="mt-3" v-if="!accessToken">
        <b-button @click="login">Login</b-button>
      </div>
      <div v-if="accessToken && !userInfo" class="loader"></div>
      <transition name="fade">
        <b-card v-if="userInfo" title="User Info" sub-title="/oauth2/userInfo">
          <b-card-text>
            <b-list-group>
              <b-list-group-item class="d-flex justify-content-between align-items-center">
                {{ userInfo.email }}
                <b-badge variant="primary" pill>email</b-badge>
              </b-list-group-item>

              <b-list-group-item class="d-flex justify-content-between align-items-center">
                {{ userInfo.sub }}
                <b-badge variant="primary" pill>sub</b-badge>
              </b-list-group-item>
            </b-list-group>
          </b-card-text>
        </b-card>
      </transition>
      <div class="mt-3" v-if="accessToken">
        <b-button @click="logout">Logout</b-button>
      </div>
    </b-jumbotron>
  </div>
</template>

<script>
import axios from "axios";

const accessToken = () =>
  new URLSearchParams(window.location.hash.split("#")[1]).get("access_token");

export default {
  name: "Login",
  data: function() {
    return {
      userInfo: ""
    };
  },
  mounted: async function() {
    if (accessToken()) {
      const response = await axios.get(
        `https://${process.env.VUE_APP_COGNITO_HOST}/oauth2/userInfo`,
        { headers: { Authorization: `Bearer ${accessToken()}` } }
      );
      this.userInfo = response.data;
    }
  },
  methods: {
    login: async () => {
      window.location.href = `https://${
        process.env.VUE_APP_COGNITO_HOST
      }/oauth2/authorize?response_type=token&client_id=${
        process.env.VUE_APP_CLIENT_ID
      }&redirect_uri=${encodeURI(process.env.VUE_APP_REDIRECT_URL)}`;
    },
    logout: async () => {
      window.location.href = `https://${
        process.env.VUE_APP_COGNITO_HOST
      }/logout?client_id=${
        process.env.VUE_APP_CLIENT_ID
      }&logout_uri=${encodeURI(process.env.VUE_APP_REDIRECT_URL)}`;
    }
  },
  computed: {
    accessToken: () => accessToken()
  }
};
</script>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease-out;
}

.fade-enter,
.fade-leave-to {
  opacity: 0;
}

.loader {
  border: 10px solid #e9ecef;
  border-top: 10px solid #fff;
  border-radius: 50%;
  width: 120px;
  height: 120px;
  animation: spin 0.5s linear infinite;
  display: block;
  margin-left: auto;
  margin-right: auto;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>
