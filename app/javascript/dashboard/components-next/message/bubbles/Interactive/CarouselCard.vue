<script setup>
import { computed } from 'vue';
import InteractiveButtons from './InteractiveButtons.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
});

const imageUrl = computed(() => {
  // Priorizar URL direta, depois base64 thumbnail
  if (props.card.image_url || props.card.imageUrl) {
    return props.card.image_url || props.card.imageUrl;
  }

  const thumbnail = props.card.image_thumbnail || props.card.imageThumbnail;
  if (thumbnail) {
    // Se já for uma URL data, usar diretamente
    if (thumbnail.startsWith('data:')) return thumbnail;
    // Se for base64 puro, adicionar prefixo
    return `data:image/jpeg;base64,${thumbnail}`;
  }

  return null;
});

const bodyText = computed(() => props.card.body || '');
const buttons = computed(() => props.card.buttons || []);
</script>

<template>
  <div
    class="flex-shrink-0 w-56 bg-n-alpha-2 rounded-xl overflow-hidden border border-n-strong"
  >
    <!-- Image -->
    <div v-if="imageUrl" class="w-full h-32 overflow-hidden">
      <img :src="imageUrl" alt="" class="w-full h-full object-cover" />
    </div>

    <!-- Body -->
    <div v-if="bodyText" class="p-3">
      <p class="text-sm line-clamp-3">{{ bodyText }}</p>
    </div>

    <!-- Buttons -->
    <div v-if="buttons.length" class="border-t border-n-strong">
      <InteractiveButtons :buttons="buttons" compact />
    </div>
  </div>
</template>
