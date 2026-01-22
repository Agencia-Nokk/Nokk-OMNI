<script setup>
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAutomation } from 'dashboard/composables/useAutomation';
import { useEditableAutomation } from 'dashboard/composables/useEditableAutomation';
import { generateAutomationPayload } from 'dashboard/helper/automationHelper';
import { validateAutomation } from 'dashboard/helper/validations';
import AutomationForm from './AutomationForm.vue';
import AutomationFlowEditor from './flow/AutomationFlowEditor.vue';
import { AUTOMATION_RULE_EVENTS, AUTOMATION_ACTION_TYPES } from './constants';

const store = useStore();
const getters = useStoreGetters();
const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const mode = ref('CREATE');
const errors = ref({});
const allCustomAttributes = ref([]);
const viewMode = ref('flow');

const start_value = {
  name: null,
  description: null,
  event_name: 'conversation_created',
  conditions: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    },
  ],
  actions: [
    {
      action_name: 'assign_agent',
      action_params: [],
    },
  ],
};

const {
  automation,
  automationTypes,
  onEventChange,
  getConditionDropdownValues,
  appendNewCondition,
  appendNewAction,
  removeFilter,
  removeAction,
  resetFilter,
  resetAction,
  getActionDropdownValues,
  manifestCustomAttributes,
} = useAutomation(start_value);

const { formatAutomation } = useEditableAutomation();

const uiFlags = computed(() => getters['automations/getUIFlags'].value);
const automationId = computed(() => route.params.automationId);
const accountId = computed(() => getters.getCurrentAccountId.value);

const isSLAEnabled = computed(() =>
  getters['accounts/isFeatureEnabledonAccount'].value(accountId.value, 'sla')
);

const automationRuleEvents = computed(() =>
  AUTOMATION_RULE_EVENTS.map(event => ({
    ...event,
    value: t(`AUTOMATION.EVENTS.${event.value}`),
  }))
);

const automationActionTypes = computed(() => {
  const actionTypes = isSLAEnabled.value
    ? AUTOMATION_ACTION_TYPES
    : AUTOMATION_ACTION_TYPES.filter(({ key }) => key !== 'add_sla');

  return actionTypes.map(action => ({
    ...action,
    label: t(`AUTOMATION.ACTIONS.${action.label}`),
  }));
});

const fetchDropdownData = () => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('contacts/get');
  store.dispatch('teams/get');
  store.dispatch('labels/get');
  store.dispatch('campaigns/get');
  store.dispatch('macros/get');
  if (isSLAEnabled.value) {
    store.dispatch('sla/get');
  }
};

const fetchAutomation = async () => {
  mode.value = 'EDIT';
  await store.dispatch('automations/get');
  const automationData = store.getters['automations/getAutomation'](
    Number(automationId.value)
  );

  if (automationData) {
    automation.value = formatAutomation(
      automationData,
      allCustomAttributes.value,
      automationTypes,
      automationActionTypes.value
    );
  }
};

const initNewAutomation = () => {
  mode.value = 'CREATE';
  automation.value = { ...start_value };
};

watch(
  () => route,
  () => {
    fetchDropdownData();
    manifestCustomAttributes();
    allCustomAttributes.value = store.getters['attributes/getAttributes'];

    if (route.params.automationId) {
      fetchAutomation();
    } else {
      initNewAutomation();
    }
  },
  { immediate: true, deep: true }
);

const saveAutomation = async automationData => {
  errors.value = validateAutomation(automationData);
  if (Object.keys(errors.value).length !== 0) return;

  try {
    const action =
      mode.value === 'EDIT' ? 'automations/update' : 'automations/create';
    const successMessage =
      mode.value === 'EDIT'
        ? t('AUTOMATION.EDIT.API.SUCCESS_MESSAGE')
        : t('AUTOMATION.ADD.API.SUCCESS_MESSAGE');

    const payload = generateAutomationPayload(automationData);
    await store.dispatch(action, payload);
    useAlert(successMessage);
    router.push({ name: 'automation_list' });
  } catch (error) {
    const errorMessage =
      mode.value === 'EDIT'
        ? t('AUTOMATION.EDIT.API.ERROR_MESSAGE')
        : t('AUTOMATION.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
};

const onCancel = () => {
  router.push({ name: 'automation_list' });
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto">
    <woot-loading-state
      v-if="uiFlags.isFetching"
      :message="$t('AUTOMATION.LOADING')"
    />
    <div v-if="automation && !uiFlags.isFetching" class="flex flex-col h-full">
      <!-- Toggle de Modo -->
      <div class="flex items-center justify-start gap-2 p-4">
        <button
          class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          :class="[
            viewMode === 'form'
              ? 'bg-n-blue-9 text-white'
              : 'bg-n-slate-3 dark:bg-n-solid-3 text-n-slate-11 hover:bg-n-slate-4',
          ]"
          @click="viewMode = 'form'"
        >
          <i class="ion-document-text mr-2" />
          {{ $t('AUTOMATION.FLOW.VIEW_FORM') }}
        </button>
        <button
          class="px-4 py-2 rounded-lg text-sm font-medium transition-colors"
          :class="[
            viewMode === 'flow'
              ? 'bg-n-blue-9 text-white'
              : 'bg-n-slate-3 dark:bg-n-solid-3 text-n-slate-11 hover:bg-n-slate-4',
          ]"
          @click="viewMode = 'flow'"
        >
          <i class="ion-share-alt mr-2" />
          {{ $t('AUTOMATION.FLOW.VIEW_FLOW') }}
        </button>
      </div>

      <!-- Modo Formulário -->
      <AutomationForm
        v-if="viewMode === 'form'"
        :automation-data="automation"
        :automation-types="automationTypes"
        :automation-rule-events="automationRuleEvents"
        :automation-action-types="automationActionTypes"
        :all-custom-attributes="allCustomAttributes"
        :mode="mode.toLowerCase()"
        :errors="errors"
        :get-condition-dropdown-values="getConditionDropdownValues"
        :get-action-dropdown-values="getActionDropdownValues"
        @update:automation-data="automation = $event"
        @submit="saveAutomation"
        @cancel="onCancel"
        @event-change="onEventChange"
        @append-new-condition="appendNewCondition"
        @append-new-action="appendNewAction"
        @remove-filter="removeFilter"
        @remove-action="removeAction"
        @reset-filter="resetFilter"
        @reset-action="resetAction"
      />

      <!-- Modo Visual Flow -->
      <div v-else class="flex-1">
        <AutomationFlowEditor
          :automation-data="automation"
          :automation-types="automationTypes"
          :automation-rule-events="automationRuleEvents"
          :automation-action-types="automationActionTypes"
          :all-custom-attributes="allCustomAttributes"
          :get-condition-dropdown-values="getConditionDropdownValues"
          :get-action-dropdown-values="getActionDropdownValues"
          @update:automation-data="automation = $event"
          @save="saveAutomation(automation)"
          @cancel="onCancel"
        />
      </div>
    </div>
  </div>
</template>
