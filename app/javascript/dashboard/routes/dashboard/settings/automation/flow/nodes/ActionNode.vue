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

const actionSummary = computed(() => {
  const { action_name, action_params } = props.data;

  if (!action_name) {
    return t('AUTOMATION.FLOW.ACTION_EMPTY');
  }

  const actionKey = action_name.toUpperCase();
  const actionLabel = t(`AUTOMATION.ACTIONS.${actionKey}`) || action_name;

  if (action_params && action_params.length > 0) {
    const paramsPreview = Array.isArray(action_params)
      ? action_params.slice(0, 2).join(', ')
      : String(action_params).substring(0, 30);
    return `${actionLabel}: ${paramsPreview}`;
  }

  return actionLabel;
});

const handleDelete = event => {
  event.stopPropagation();
  deleteNode(props.id);
};
</script>

<template>
  <div
    class="relative bg-n-blue-9 dark:bg-n-blue-10 text-white rounded-lg shadow-lg border-2 min-w-[200px] group"
    :class="[
      selected ? 'border-n-blue-11 ring-2 ring-n-blue-11' : 'border-n-blue-10',
    ]"
  >
    <!-- Botão de delete -->
    <button
      class="absolute -top-2 -right-2 w-6 h-6 bg-n-ruby-9 hover:bg-n-ruby-10 text-white rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity z-10"
      :title="$t('AUTOMATION.FLOW.DELETE_NODE')"
      @click="handleDelete"
    >
      <i class="ion-close text-sm" />
    </button>

    <div class="px-4 py-3">
      <div class="flex items-center gap-2 mb-2">
        <span class="text-xs font-semibold uppercase tracking-wide opacity-80">
          {{ $t('AUTOMATION.FLOW.ACTION') }}
        </span>
      </div>
      <div class="text-sm font-medium line-clamp-2">
        {{ actionSummary }}
      </div>
    </div>

    <Handle
      type="target"
      :position="Position.Left"
      class="!bg-n-blue-11 !w-3 !h-3 !border-2 !border-white"
    />
    <Handle
      type="source"
      :position="Position.Right"
      class="!bg-n-blue-11 !w-3 !h-3 !border-2 !border-white"
    />
  </div>
</template>
