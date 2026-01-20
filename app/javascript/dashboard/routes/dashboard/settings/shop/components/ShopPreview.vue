<script setup>
import { computed, ref } from 'vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  publicUrl: {
    type: String,
    required: true,
  },
  viewMode: {
    type: String,
    default: 'desktop',
    validator: value => ['mobile', 'tablet', 'desktop'].includes(value),
  },
});

const isLoading = ref(true);
const iframeKey = ref(0);

const containerClass = computed(() => {
  switch (props.viewMode) {
    case 'mobile':
      return 'w-[375px]';
    case 'tablet':
      return 'w-[768px]';
    default:
      return 'w-full';
  }
});

const containerHeight = computed(() => {
  switch (props.viewMode) {
    case 'mobile':
      return 'h-[667px]';
    case 'tablet':
      return 'h-[600px]';
    default:
      return 'h-full min-h-[500px]';
  }
});

// Construir URL completa
const iframeSrc = computed(() => {
  const baseUrl = window.location.origin;
  // Adiciona timestamp para forçar refresh quando necessário
  return `${baseUrl}${props.publicUrl}?preview=1&t=${iframeKey.value}`;
});

function onIframeLoad() {
  isLoading.value = false;
}

function refreshPreview() {
  isLoading.value = true;
  iframeKey.value = Date.now();
}

// Expor função de refresh
defineExpose({ refreshPreview });
</script>

<template>
  <div
    class="shop-preview-container rounded-xl overflow-hidden border border-slate-200 dark:border-slate-700 mx-auto transition-all duration-300 bg-white"
    :class="[containerClass, containerHeight]"
  >
    <!-- Loading -->
    <div
      v-if="isLoading"
      class="absolute inset-0 flex items-center justify-center bg-slate-50 dark:bg-slate-800 z-10"
    >
      <div class="text-center">
        <Spinner :size="32" />
        <p class="text-sm text-slate-500 dark:text-slate-400 mt-3">
          {{ $t('SHOP.SETTINGS.PREVIEW.LOADING') }}
        </p>
      </div>
    </div>

    <!-- Iframe com a loja real -->
    <iframe
      :key="iframeKey"
      :src="iframeSrc"
      class="w-full h-full border-0"
      :title="$t('SHOP.SETTINGS.PREVIEW.TITLE')"
      @load="onIframeLoad"
    />
  </div>
</template>

<style scoped>
.shop-preview-container {
  position: relative;
}
</style>
