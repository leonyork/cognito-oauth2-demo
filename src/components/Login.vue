<template>
  <div>
    <b-jumbotron header="Cognito" :lead="visibleMessage">
      <div class="mt-3" v-if="!accessToken">
        <b-button @click="login">Login</b-button>
      </div>
      <div v-if="accessToken && !userInfo" class="loader"></div>
      <transition name="fade">
        <b-card
          v-if="userInfo"
          title="Store a welcome message"
          :sub-title="'PUT /user/' + userInfo.sub"
        >
          <b-card-text>
            <b-form @submit.prevent="save()">
              <div class="row">
                <div class="col-sm-10">
                  <b-form-input
                    v-model="message"
                    required
                    placeholder="Enter a message"
                    style="width: 100%;"
                  ></b-form-input>
                </div>
                <div class="col-sm-2">
                  <b-button type="submit" variant="primary" style="width: 100%;">Save</b-button>
                </div>
              </div>
            </b-form>
          </b-card-text>
        </b-card>
      </transition>
      <transition name="fade">
        <b-card v-if="userInfo" title="User Info" sub-title="GET /oauth2/userInfo">
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
      userInfo: "",
      message: "",
      visibleMessage: "Testing the OAuth2 flow with Cognito"
    };
  },
  mounted: async function() {
    if (accessToken()) {
      let response = await axios.get(
        `https://${process.env.VUE_APP_COGNITO_HOST}/oauth2/userInfo`,
        { headers: { Authorization: `Bearer ${accessToken()}` } }
      );
      this.userInfo = response.data;

      try {
        response = await axios.get(
          `${process.env.VUE_APP_USER_API_URL}/user/${this.userInfo.sub}`,
          { headers: { Authorization: `Bearer ${accessToken()}` } }
        );
        this.visibleMessage = response.data.message;
      } catch (err) {
        if (err.response.status != 404) { throw err; }
      }
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
    },
    save: async function() {
      const response = await axios.put(
        `${process.env.VUE_APP_USER_API_URL}/user/${this.userInfo.sub}`,
        { message: this.message },
        { headers: { Authorization: `Bearer ${accessToken()}` } }
      );
      this.visibleMessage = response.data.message;
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
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}
</style>
