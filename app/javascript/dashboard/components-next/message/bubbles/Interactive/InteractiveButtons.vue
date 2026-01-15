<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  buttons: {
    type: Array,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  isList: {
    type: Boolean,
    default: false,
  },
});

const getButtonIcon = type => {
  switch (type) {
    case 'quick_reply':
      return 'i-lucide-reply';
    case 'cta_url':
      return 'i-lucide-external-link';
    case 'cta_call':
      return 'i-lucide-phone';
    case 'single_select':
      return 'i-lucide-list';
    default:
      return 'i-lucide-circle';
  }
};
</script>

<template>
  <div
    class="flex flex-col divide-y divide-n-strong"
    :class="{ 'bg-n-alpha-2 rounded-lg': !compact && !isList }"
  >
    <div
      v-for="(button, index) in buttons"
      :key="index"
      class="flex items-center gap-2 text-n-blue-text"
      :class="compact ? 'px-3 py-2 text-xs' : 'px-3 py-2.5 text-sm'"
    >
      <Icon :icon="getButtonIcon(button.type)" class="size-4 flex-shrink-0" />
      <span class="truncate">
        {{ button.display_text || button.displayText || 'Button' }}
      </span>
    </div>
  </div>
</template>
