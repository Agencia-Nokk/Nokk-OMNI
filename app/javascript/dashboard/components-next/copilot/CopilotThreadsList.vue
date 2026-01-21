<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from '../icon/Icon.vue';
import Button from '../button/Button.vue';

const props = defineProps({
  threads: {
    type: Array,
    default: () => [],
  },
  activeThreadId: {
    type: Number,
    default: null,
  },
});

const emit = defineEmits(['selectThread', 'newThread']);

const { t } = useI18n();

const formatDate = date => {
  if (!date) return '';
  const d = new Date(date * 1000);
  const now = new Date();
  const diffMs = now - d;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);

  if (diffMins < 1) return t('GENERAL.JUST_NOW');
  if (diffMins < 60) return t('GENERAL.MINUTES_AGO', { count: diffMins });
  if (diffHours < 24) return t('GENERAL.HOURS_AGO', { count: diffHours });
  if (diffDays < 7) return t('GENERAL.DAYS_AGO', { count: diffDays });

  return d.toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const hasThreads = computed(() => props.threads.length > 0);

const handleThreadClick = thread => {
  emit('selectThread', thread);
};

const handleNewThread = () => {
  emit('newThread');
};
</script>

<template>
  <div class="flex-1 flex flex-col gap-6 px-4 py-4 overflow-y-auto">
    <div class="flex flex-col space-y-4 py-4">
      <div class="space-y-1">
        <h3 class="text-base font-medium text-n-slate-12 leading-8">
          {{ $t('CAPTAIN.COPILOT.HISTORY') }}
        </h3>
        <p class="text-sm text-n-slate-11 leading-6">
          {{ $t('CAPTAIN.COPILOT.SELECT_CONVERSATION') }}
        </p>
      </div>
    </div>

    <div v-if="!hasThreads" class="w-full space-y-4">
      <div class="flex flex-col items-center justify-center py-8">
        <Icon icon="i-lucide-history" class="text-n-slate-9 text-4xl mb-4" />
        <p class="text-sm text-n-slate-11 leading-6 text-center">
          {{ $t('CAPTAIN.COPILOT.NO_HISTORY') }}
        </p>
      </div>
      <Button
        :label="$t('CAPTAIN.COPILOT.NEW_CONVERSATION')"
        icon="i-lucide-plus"
        variant="solid"
        size="md"
        class="w-full"
        @click="handleNewThread"
      />
    </div>

    <div v-else class="w-full space-y-2">
      <Button
        :label="$t('CAPTAIN.COPILOT.NEW_CONVERSATION')"
        icon="i-lucide-plus"
        variant="outline"
        size="md"
        class="w-full mb-4"
        @click="handleNewThread"
      />
      <div class="space-y-1">
        <button
          v-for="thread in threads"
          :key="thread.id"
          class="w-full px-3 py-3 rounded-md border border-n-weak bg-n-slate-2 text-n-slate-11 flex flex-col items-start gap-1 hover:bg-n-slate-3 transition-colors text-left"
          :class="{
            'border-n-slate-8 bg-n-slate-3': thread.id === activeThreadId,
          }"
          @click="handleThreadClick(thread)"
        >
          <div class="flex items-center justify-between w-full">
            <span class="text-sm font-medium text-n-slate-12 line-clamp-1">
              {{ thread.title }}
            </span>
            <div
              v-if="thread.id === activeThreadId"
              class="flex items-center justify-center flex-shrink-0 w-4 h-4 rounded-full bg-n-slate-12 dark:bg-n-slate-11"
            >
              <i class="i-lucide-check text-white dark:text-n-slate-1 size-3" />
            </div>
          </div>
          <span class="text-xs text-n-slate-10">
            {{ formatDate(thread.created_at) }}
          </span>
        </button>
      </div>
    </div>
  </div>
</template>
