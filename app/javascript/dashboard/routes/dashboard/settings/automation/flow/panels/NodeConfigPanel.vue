<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import FilterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import {
  getAttributes,
  getInputType,
  getOperators,
  getCustomAttributeType,
  showActionInput,
} from 'dashboard/helper/automationHelper';
import { AUTOMATION_RULE_EVENTS } from '../../constants';

const props = defineProps({
  selectedNode: {
    type: Object,
    default: null,
  },
  automationTypes: {
    type: Object,
    required: true,
  },
  automationActionTypes: {
    type: Array,
    required: true,
  },
  allCustomAttributes: {
    type: Array,
    default: () => [],
  },
  eventName: {
    type: String,
    required: true,
  },
  getConditionDropdownValues: {
    type: Function,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['update:node', 'close']);

const { t } = useI18n();

const nodeType = computed(() => props.selectedNode?.type || null);
const nodeData = computed(() => props.selectedNode?.data || {});

// Mapeamento estático de traduções de eventos
const EVENT_TRANSLATIONS = {
  CONVERSATION_CREATED: 'AUTOMATION.EVENTS.CONVERSATION_CREATED',
  CONVERSATION_UPDATED: 'AUTOMATION.EVENTS.CONVERSATION_UPDATED',
  CONVERSATION_RESOLVED: 'AUTOMATION.EVENTS.CONVERSATION_RESOLVED',
  CONVERSATION_OPENED: 'AUTOMATION.EVENTS.CONVERSATION_OPENED',
  MESSAGE_CREATED: 'AUTOMATION.EVENTS.MESSAGE_CREATED',
};

// Mapeamento estático de traduções de atributos
const ATTRIBUTE_TRANSLATIONS = {
  MESSAGE_TYPE: 'AUTOMATION.ATTRIBUTES.MESSAGE_TYPE',
  MESSAGE_CONTAINS: 'AUTOMATION.ATTRIBUTES.MESSAGE_CONTAINS',
  EMAIL: 'AUTOMATION.ATTRIBUTES.EMAIL',
  INBOX: 'AUTOMATION.ATTRIBUTES.INBOX',
  STATUS: 'AUTOMATION.ATTRIBUTES.STATUS',
  ASSIGNEE_NAME: 'AUTOMATION.ATTRIBUTES.ASSIGNEE_NAME',
  TEAM_NAME: 'AUTOMATION.ATTRIBUTES.TEAM_NAME',
  PRIORITY: 'AUTOMATION.ATTRIBUTES.PRIORITY',
  CONVERSATION_LANGUAGE: 'AUTOMATION.ATTRIBUTES.CONVERSATION_LANGUAGE',
  PHONE_NUMBER: 'AUTOMATION.ATTRIBUTES.PHONE_NUMBER',
  LABELS: 'AUTOMATION.ATTRIBUTES.LABELS',
  BROWSER_LANGUAGE: 'AUTOMATION.ATTRIBUTES.BROWSER_LANGUAGE',
  MAIL_SUBJECT: 'AUTOMATION.ATTRIBUTES.MAIL_SUBJECT',
  COUNTRY_NAME: 'AUTOMATION.ATTRIBUTES.COUNTRY_NAME',
  REFERER_LINK: 'AUTOMATION.ATTRIBUTES.REFERER_LINK',
};

const automationRuleEvents = computed(() =>
  AUTOMATION_RULE_EVENTS.map(event => {
    const translationKey = EVENT_TRANSLATIONS[event.value];
    return {
      ...event,
      // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
      value: translationKey ? t(translationKey) : event.value,
    };
  })
);

const getTranslatedAttributes = (type, event) => {
  return getAttributes(type, event).map(attribute => {
    const skipTranslation =
      attribute.customAttributeType ||
      ['contact_custom_attribute', 'conversation_custom_attribute'].includes(
        attribute.key
      );

    const translationKey = ATTRIBUTE_TRANSLATIONS[attribute.name];
    return {
      ...attribute,
      // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
      name:
        skipTranslation || !translationKey ? attribute.name : t(translationKey),
    };
  });
};

const updateNodeData = updatedData => {
  emit('update:node', {
    ...props.selectedNode,
    data: { ...nodeData.value, ...updatedData },
  });
};

const updateTriggerEvent = eventName => {
  updateNodeData({ event_name: eventName });
};

const updateCondition = condition => {
  updateNodeData(condition);
};

const updateAction = action => {
  updateNodeData(action);
};
</script>

<template>
  <div
    v-show="selectedNode"
    class="h-full w-80 flex-shrink-0 bg-n-slate-1 dark:bg-n-solid-1 border-r border-n-strong overflow-y-auto"
  >
    <div class="p-4">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ $t('AUTOMATION.FLOW.CONFIGURE_NODE') }}
        </h3>
        <button
          class="text-n-slate-11 hover:text-n-slate-12"
          @click="$emit('close')"
        >
          <i class="ion-close text-xl" />
        </button>
      </div>

      <!-- Trigger Node Configuration -->
      <div v-if="nodeType === 'trigger'" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-n-slate-11 mb-2">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
          </label>
          <select
            :value="nodeData.event_name"
            class="w-full rounded-lg border border-n-strong bg-n-slate-1 dark:bg-n-solid-2 px-3 py-2 text-n-slate-12"
            @change="updateTriggerEvent($event.target.value)"
          >
            <option
              v-for="event in automationRuleEvents"
              :key="event.key"
              :value="event.key"
            >
              {{ event.value }}
            </option>
          </select>
        </div>
      </div>

      <!-- Condition Node Configuration -->
      <div v-if="nodeType === 'condition'" class="space-y-4">
        <FilterInputBox
          :model-value="nodeData"
          :filter-attributes="
            getTranslatedAttributes(automationTypes, eventName)
          "
          :input-type="
            getInputType(
              allCustomAttributes,
              automationTypes,
              { event_name: eventName },
              nodeData.attribute_key
            )
          "
          :operators="
            getOperators(
              allCustomAttributes,
              automationTypes,
              { event_name: eventName },
              'create',
              nodeData.attribute_key
            )
          "
          :dropdown-values="getConditionDropdownValues(nodeData.attribute_key)"
          show-query-operator
          :custom-attribute-type="
            getCustomAttributeType(
              automationTypes,
              { event_name: eventName },
              nodeData.attribute_key
            )
          "
          @update:model-value="updateCondition"
        />
      </div>

      <!-- Action Node Configuration -->
      <div v-if="nodeType === 'action'" class="space-y-4">
        <AutomationActionInput
          :model-value="nodeData"
          :action-types="automationActionTypes"
          :dropdown-values="getActionDropdownValues(nodeData.action_name)"
          :show-action-input="
            showActionInput(automationActionTypes, nodeData.action_name)
          "
          @update:model-value="updateAction"
        />
      </div>
    </div>
  </div>
</template>
