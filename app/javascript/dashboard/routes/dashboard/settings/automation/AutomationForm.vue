<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import FilterInputBox from 'dashboard/components/widgets/FilterInput/Index.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AutomationProperties from './AutomationProperties.vue';
import {
  getAttributes,
  getInputType,
  getOperators,
  getCustomAttributeType,
  showActionInput,
} from 'dashboard/helper/automationHelper';

const props = defineProps({
  automationData: {
    type: Object,
    default: () => ({}),
  },
  automationTypes: {
    type: Object,
    default: () => ({}),
  },
  automationRuleEvents: {
    type: Array,
    default: () => [],
  },
  automationActionTypes: {
    type: Array,
    default: () => [],
  },
  allCustomAttributes: {
    type: Array,
    default: () => [],
  },
  mode: {
    type: String,
    default: 'create',
  },
  errors: {
    type: Object,
    default: () => ({}),
  },
  getConditionDropdownValues: {
    type: Function,
    default: () => [],
  },
  getActionDropdownValues: {
    type: Function,
    default: () => [],
  },
});

const emit = defineEmits([
  'submit',
  'cancel',
  'update:automationData',
  'eventChange',
  'appendNewCondition',
  'appendNewAction',
  'removeFilter',
  'removeAction',
  'resetFilter',
  'resetAction',
]);

const { t } = useI18n();
const automation = ref(props.automationData);

watch(
  () => props.automationData,
  newVal => {
    automation.value = newVal;
  },
  { immediate: true, deep: true }
);

const hasAutomationMutated = computed(() => {
  if (!automation.value?.conditions || !automation.value?.actions) return false;
  if (
    automation.value.conditions[0]?.values ||
    automation.value.actions[0]?.action_params?.length
  )
    return true;
  return false;
});

const updateName = value => {
  automation.value.name = value;
  emit('update:automationData', automation.value);
};

const updateDescription = value => {
  automation.value.description = value;
  emit('update:automationData', automation.value);
};

const onEventChange = () => {
  emit('eventChange', automation.value);
};

const getTranslatedAttributes = (type, event) => {
  return getAttributes(type, event).map(attribute => {
    const skipTranslation =
      attribute.customAttributeType ||
      ['contact_custom_attribute', 'conversation_custom_attribute'].includes(
        attribute.key
      );

    return {
      ...attribute,
      name: skipTranslation
        ? attribute.name
        : t(`AUTOMATION.ATTRIBUTES.${attribute.name}`),
    };
  });
};

const submit = () => {
  emit('submit', automation.value);
};
</script>

<template>
  <div class="flex flex-col w-full h-auto md:flex-row md:h-full">
    <div
      class="flex-1 w-full h-full max-h-full px-8 py-6 overflow-y-auto md:w-auto"
    >
      <div class="max-w-3xl">
        <div class="mb-6">
          <label :class="{ error: errors.event_name }">
            {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
            <select
              v-model="automation.event_name"
              class="m-0"
              @change="onEventChange"
            >
              <option
                v-for="event in automationRuleEvents"
                :key="event.key"
                :value="event.key"
              >
                {{ event.value }}
              </option>
            </select>
            <span v-if="errors.event_name" class="message">
              {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
            </span>
          </label>
          <p
            v-if="hasAutomationMutated"
            class="text-xs text-right text-n-teal-10 pt-1"
          >
            {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
          </p>
        </div>

        <section class="mb-6">
          <label>
            {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
          </label>
          <div
            class="w-full p-4 border border-solid rounded-lg bg-n-slate-2 dark:bg-n-solid-2 border-n-strong"
          >
            <FilterInputBox
              v-for="(condition, i) in automation.conditions"
              :key="i"
              v-model="automation.conditions[i]"
              :filter-attributes="
                getTranslatedAttributes(automationTypes, automation.event_name)
              "
              :input-type="
                getInputType(
                  allCustomAttributes,
                  automationTypes,
                  automation,
                  automation.conditions[i].attribute_key
                )
              "
              :operators="
                getOperators(
                  allCustomAttributes,
                  automationTypes,
                  automation,
                  mode,
                  automation.conditions[i].attribute_key
                )
              "
              :dropdown-values="
                props.getConditionDropdownValues(
                  automation.conditions[i].attribute_key
                )
              "
              :show-query-operator="i !== automation.conditions.length - 1"
              :custom-attribute-type="
                getCustomAttributeType(
                  automationTypes,
                  automation,
                  automation.conditions[i].attribute_key
                )
              "
              :error-message="
                errors[`condition_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`condition_${i}`]}`)
                  : ''
              "
              @reset-filter="$emit('resetFilter', i, automation.conditions[i])"
              @remove-filter="$emit('removeFilter', i)"
            />
            <div class="mt-4">
              <NextButton
                icon="i-lucide-plus"
                blue
                faded
                sm
                :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
                @click="$emit('appendNewCondition')"
              />
            </div>
          </div>
        </section>

        <section class="mb-6">
          <label>
            {{ $t('AUTOMATION.ADD.FORM.ACTIONS.LABEL') }}
          </label>
          <div
            class="w-full p-4 border border-solid rounded-lg bg-n-slate-2 dark:bg-n-solid-2 border-n-strong"
          >
            <AutomationActionInput
              v-for="(action, i) in automation.actions"
              :key="i"
              v-model="automation.actions[i]"
              :action-types="automationActionTypes"
              :dropdown-values="
                props.getActionDropdownValues(automation.actions[i].action_name)
              "
              :show-action-input="
                showActionInput(
                  automationActionTypes,
                  automation.actions[i].action_name
                )
              "
              :error-message="
                errors[`action_${i}`]
                  ? $t(`AUTOMATION.ERRORS.${errors[`action_${i}`]}`)
                  : ''
              "
              @reset-action="$emit('resetAction', i)"
              @remove-action="$emit('removeAction', i)"
            />
            <div class="mt-4">
              <NextButton
                icon="i-lucide-plus"
                blue
                faded
                sm
                :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
                @click="$emit('appendNewAction')"
              />
            </div>
          </div>
        </section>
      </div>
    </div>

    <div class="w-full md:w-80 pb-4 px-4 md:px-0 md:pr-4">
      <AutomationProperties
        :automation-name="automation.name"
        :automation-description="automation.description"
        :errors="errors"
        @update:name="updateName"
        @update:description="updateDescription"
        @submit="submit"
        @cancel="$emit('cancel')"
      />
    </div>
  </div>
</template>
