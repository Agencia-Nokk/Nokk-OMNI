<script setup>
import { computed, inject } from 'vue';
import { Handle, Position } from '@vue-flow/core';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  id: {
    type: String,
    required: true,
  },
  data: {
    type: Object,
    required: true,
  },
  selected: {
    type: Boolean,
    default: false,
  },
});

const deleteNode = inject('deleteNode', () => {});

const { t } = useI18n();

const conditionSummary = computed(() => {
  const { attribute_key, filter_operator, values } = props.data;

  if (!attribute_key) {
    return t('AUTOMATION.FLOW.CONDITION_EMPTY');
  }

  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
  const attributeLabel =
    t(`AUTOMATION.ATTRIBUTES.${attribute_key.toUpperCase()}`) || attribute_key;
  const operatorLabel = filter_operator || '';
  const valuesLabel = Array.isArray(values) ? values.join(', ') : values || '';

  return `${attributeLabel} ${operatorLabel} ${valuesLabel}`.trim();
});

const queryOperatorBadge = computed(() => {
  const { query_operator } = props.data;
  if (!query_operator) return null;
  return query_operator.toUpperCase();
});

const handleDelete = event => {
  event.stopPropagation();
  deleteNode(props.id);
};
</script>

<template>
  <div
    class="relative text-white rounded-lg shadow-lg border-2 min-w-[200px] max-w-[280px] group z-10 !bg-black"
    :class="[
      selected
        ? 'border-n-yellow-9 ring-2 ring-n-yellow-9'
        : 'border-n-slate-7',
    ]"
  >
    <!-- Botão de delete -->
    <button
      class="absolute -top-2 -right-2 w-6 h-6 bg-n-ruby-9 hover:bg-n-ruby-10 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity z-20"
      :title="$t('AUTOMATION.FLOW.DELETE_NODE')"
      @click="handleDelete"
    >
      <i class="ion-close text-sm" />
    </button>

    <div class="px-4 py-3">
      <div class="flex items-center justify-between gap-2 mb-2">
        <span
          class="text-xs font-semibold uppercase tracking-wide text-n-yellow-9"
        >
          {{ $t('AUTOMATION.FLOW.CONDITION') }}
        </span>
        <span
          v-if="queryOperatorBadge"
          class="px-2 py-0.5 text-xs font-bold bg-n-yellow-9 text-black rounded"
        >
          {{ queryOperatorBadge }}
        </span>
      </div>
      <div class="text-sm font-medium truncate" :title="conditionSummary">
        {{ conditionSummary }}
      </div>
    </div>

    <Handle
      type="target"
      :position="Position.Left"
      class="!bg-n-yellow-9 !w-3 !h-3 !border-2 !border-white"
    />
    <Handle
      type="source"
      :position="Position.Right"
      class="!bg-n-yellow-9 !w-3 !h-3 !border-2 !border-white"
    />
  </div>
</template>
