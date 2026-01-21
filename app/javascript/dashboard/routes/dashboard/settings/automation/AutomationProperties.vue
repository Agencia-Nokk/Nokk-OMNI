<script setup>
import NextButton from 'dashboard/components-next/button/Button.vue';

defineProps({
  automationName: {
    type: String,
    default: '',
  },
  automationDescription: {
    type: String,
    default: '',
  },
  errors: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits([
  'update:name',
  'update:description',
  'submit',
  'cancel',
]);

const onUpdateName = value => {
  emit('update:name', value);
};

const onUpdateDescription = value => {
  emit('update:description', value);
};
</script>

<template>
  <div
    class="p-4 bg-n-solid-2 border border-n-weak rounded-lg shadow-sm h-full flex flex-col"
  >
    <div>
      <woot-input
        :model-value="automationName"
        :label="$t('AUTOMATION.ADD.FORM.NAME.LABEL')"
        :placeholder="$t('AUTOMATION.ADD.FORM.NAME.PLACEHOLDER')"
        :error="errors.name ? $t('AUTOMATION.ADD.FORM.NAME.ERROR') : null"
        :class="{ error: errors.name }"
        @update:model-value="onUpdateName"
      />
    </div>
    <div class="mt-2">
      <woot-input
        :model-value="automationDescription"
        :label="$t('AUTOMATION.ADD.FORM.DESC.LABEL')"
        :placeholder="$t('AUTOMATION.ADD.FORM.DESC.PLACEHOLDER')"
        :error="
          errors.description ? $t('AUTOMATION.ADD.FORM.DESC.ERROR') : null
        "
        :class="{ error: errors.description }"
        @update:model-value="onUpdateDescription"
      />
    </div>
    <div
      class="mt-4 flex items-start p-2 bg-n-slate-3 dark:bg-n-solid-3 rounded-md"
    >
      <fluent-icon icon="info" size="16" class="flex-shrink-0 mt-0.5" />
      <p class="ml-2 rtl:ml-0 rtl:mr-2 mb-0 text-n-slate-11 text-xs">
        {{ $t('AUTOMATION.FORM.EDIT_NOTE') }}
      </p>
    </div>
    <div class="mt-auto w-full flex flex-col gap-2">
      <NextButton
        blue
        solid
        :label="$t('AUTOMATION.ADD.SUBMIT')"
        class="w-full"
        @click="$emit('submit')"
      />
      <NextButton
        slate
        faded
        :label="$t('AUTOMATION.ADD.CANCEL_BUTTON_TEXT')"
        class="w-full"
        @click="$emit('cancel')"
      />
    </div>
  </div>
</template>
