<script setup>
import { computed } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import { useI18n } from 'vue-i18n';
import { AUTOMATION_RULE_EVENTS } from '../../constants';

const props = defineProps({
  data: {
    type: Object,
    required: true,
  },
  selected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:data']);

const { t } = useI18n();

const eventName = computed({
  get: () => props.data.event_name || 'conversation_created',
  set: value => {
    emit('update:data', { ...props.data, event_name: value });
  },
});

const currentEventLabel = computed(() => {
  const event = AUTOMATION_RULE_EVENTS.find(e => e.key === eventName.value);
  return event ? t(`AUTOMATION.EVENTS.${event.value}`) : eventName.value;
});
</script>

<template>
  <div
    class="relative bg-n-teal-9 dark:bg-n-teal-10 text-white rounded-lg shadow-lg border-2 min-w-[200px]"
    :class="[
      selected ? 'border-n-teal-11 ring-2 ring-n-teal-11' : 'border-n-teal-10',
    ]"
  >
    <div class="px-4 py-3">
      <div class="flex items-center gap-2 mb-2">
        <span class="text-xs font-semibold uppercase tracking-wide opacity-80">
          {{ $t('AUTOMATION.FLOW.TRIGGER') }}
        </span>
      </div>
      <div class="text-sm font-medium">
        {{ currentEventLabel }}
      </div>
    </div>

    <Handle
      type="source"
      :position="Position.Right"
      class="!bg-n-teal-11 !w-3 !h-3 !border-2 !border-white"
    />
  </div>
</template>
