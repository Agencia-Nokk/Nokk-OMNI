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
      createdInboxId: null,
      isSyncing: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
      getInbox: 'inboxes/getInbox',
    }),
    currentInbox() {
      return this.createdInboxId ? this.getInbox(this.createdInboxId) : null;
    },
    syncStatus() {
      return this.currentInbox?.sync_status || 'pending';
    },
  },
  watch: {
    currentInbox: {
      handler(inbox) {
        if (!inbox) return;

        // Navigate to next step when sync is done
        if (
          inbox.sync_status === 'completed' ||
          inbox.sync_status === 'failed'
        ) {
          this.navigateToNextStep();
        }
      },
      deep: true,
    },
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

        this.createdInboxId = uazapiChannel.id;
        this.isSyncing = true;

        // Set a timeout to proceed even if sync takes too long
        setTimeout(() => {
          if (this.isSyncing) {
            this.navigateToNextStep();
          }
        }, 60000); // 60 seconds timeout
      } catch (error) {
        useAlert(
          error.message || this.$t('INBOX_MGMT.ADD.UAZAPI.API.ERROR_MESSAGE')
        );
      }
    },
    navigateToNextStep() {
      if (!this.createdInboxId) return;
      router.replace({
        name: 'settings_inboxes_add_agents',
        params: {
          page: 'new',
          inbox_id: this.createdInboxId,
        },
      });
    },
  },
};
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <!-- Sync Loading UI -->
    <div
      v-if="isSyncing"
      class="flex flex-col items-center justify-center py-12"
    >
      <div class="mb-6">
        <svg
          class="animate-spin h-12 w-12 text-woot-500"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            class="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            stroke-width="4"
          />
          <path
            class="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      </div>
      <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100 mb-2">
        {{ $t('INBOX_MGMT.ADD.UAZAPI.SYNC.TITLE') }}
      </h3>
      <p
        class="text-sm text-slate-600 dark:text-slate-300 text-center max-w-md"
      >
        {{ $t('INBOX_MGMT.ADD.UAZAPI.SYNC.DESC') }}
      </p>
    </div>

    <!-- Channel Setup Form -->
    <template v-else>
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
              :placeholder="
                $t('INBOX_MGMT.ADD.UAZAPI.PHONE_NUMBER.PLACEHOLDER')
              "
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
    </template>
  </div>
</template>
