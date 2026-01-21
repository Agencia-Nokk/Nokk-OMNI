<script setup>
import Button from './button/Button.vue';
import Icon from './icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  icon: {
    type: String,
    default: null,
  },
  buttons: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = button => {
  emit('click', button.key);
};
</script>

<template>
  <div
    class="flex items-center justify-between px-4 py-2 border-b border-n-weak h-12"
  >
    <div class="flex items-center justify-between gap-2 flex-1">
      <div class="flex items-center gap-2">
        <Icon v-if="icon" :icon="icon" class="w-20 h-20 text-n-slate-11" />
        <span class="font-medium text-sm text-n-slate-12">{{ title }}</span>
      </div>
      <div class="flex items-center">
        <Button
          v-for="button in buttons"
          :key="button.key"
          v-tooltip="button.tooltip"
          :icon="button.icon"
          ghost
          sm
          @click="handleButtonClick(button)"
        />
        <Button
          v-tooltip="$t('GENERAL.CLOSE')"
          icon="i-lucide-x"
          ghost
          sm
          @click="$emit('close')"
        />
      </div>
    </div>
  </div>
</template>
