<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

import { isPhoneE164OrEmpty } from 'shared/helpers/Validators';

export default {
  components: {
    PageHeader,
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      inboxName: '',
      phoneNumber: '',
      apiUrl: '',
      apiToken: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    inboxName: { required },
    phoneNumber: { required, isPhoneE164OrEmpty },
    apiUrl: { required },
    apiToken: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const uazapiChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.inboxName?.trim(),
            channel: {
              type: 'uazapi',
              phone_number: this.phoneNumber,
              provider_config: {
                api_url: this.apiUrl,
                api_token: this.apiToken,
              },
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: uazapiChannel.id,
          },
        });
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.UAZAPI.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <PageHeader
      :header-title="$t('INBOX_MGMT.ADD.UAZAPI.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.UAZAPI.DESC')"
    />
    <form
      class="flex flex-wrap flex-col mx-0"
      @submit.prevent="createChannel()"
    >
      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.inboxName.$error }">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME.LABEL') }}
          <input
            v-model="inboxName"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME.PLACEHOLDER')"
            @blur="v$.inboxName.$touch"
          />
          <span v-if="v$.inboxName.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.UAZAPI.INBOX_NAME.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.PHONE_NUMBER.LABEL') }}
          <input
            v-model="phoneNumber"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.UAZAPI.PHONE_NUMBER.PLACEHOLDER')"
            @blur="v$.phoneNumber.$touch"
          />
          <span v-if="v$.phoneNumber.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.UAZAPI.PHONE_NUMBER.ERROR') }}
          </span>
        </label>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.apiUrl.$error }">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.API_URL.LABEL') }}
          <input
            v-model="apiUrl"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.UAZAPI.API_URL.PLACEHOLDER')"
            @blur="v$.apiUrl.$touch"
          />
          <span v-if="v$.apiUrl.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.UAZAPI.API_URL.ERROR') }}
          </span>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.API_URL.SUBTITLE') }}
        </p>
      </div>

      <div class="flex-shrink-0 flex-grow-0">
        <label :class="{ error: v$.apiToken.$error }">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.API_TOKEN.LABEL') }}
          <input
            v-model="apiToken"
            type="password"
            :placeholder="$t('INBOX_MGMT.ADD.UAZAPI.API_TOKEN.PLACEHOLDER')"
            @blur="v$.apiToken.$touch"
          />
          <span v-if="v$.apiToken.$error" class="message">
            {{ $t('INBOX_MGMT.ADD.UAZAPI.API_TOKEN.ERROR') }}
          </span>
        </label>
        <p class="help-text">
          {{ $t('INBOX_MGMT.ADD.UAZAPI.API_TOKEN.SUBTITLE') }}
        </p>
      </div>

      <div class="w-full mt-4">
        <NextButton
          :is-loading="uiFlags.isCreating"
          type="submit"
          solid
          blue
          :label="$t('INBOX_MGMT.ADD.UAZAPI.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>
