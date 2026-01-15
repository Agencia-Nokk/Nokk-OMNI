<script setup>
import { computed } from 'vue';
import BaseBubble from 'next/message/bubbles/Base.vue';
import FormattedContent from 'next/message/bubbles/Text/FormattedContent.vue';
import { useMessageContext } from '../../provider.js';
import CarouselCard from './CarouselCard.vue';
import InteractiveButtons from './InteractiveButtons.vue';

const { content, contentAttributes } = useMessageContext();

const interactiveType = computed(() => {
  return (
    contentAttributes.value?.interactiveType ||
    contentAttributes.value?.interactive_type
  );
});

const interactiveData = computed(() => {
  return (
    contentAttributes.value?.interactiveData ||
    contentAttributes.value?.interactive_data ||
    {}
  );
});

const isCarousel = computed(() => interactiveType.value === 'carousel');
const isButtons = computed(() => interactiveType.value === 'buttons');
const isList = computed(() => interactiveType.value === 'list');

const cards = computed(() => interactiveData.value?.cards || []);
const buttons = computed(() => interactiveData.value?.buttons || []);
const bodyText = computed(() => interactiveData.value?.body || content.value);
</script>

<template>
  <BaseBubble class="px-4 py-3 overflow-hidden" data-bubble-name="interactive">
    <!-- Carousel -->
    <div v-if="isCarousel" class="flex flex-col gap-3">
      <div
        class="flex gap-2 overflow-x-auto pb-2 -mx-1 px-1 snap-x snap-mandatory"
      >
        <CarouselCard
          v-for="(card, index) in cards"
          :key="index"
          :card="card"
          class="snap-start"
        />
      </div>
      <span class="text-xs text-n-slate-11">
        {{ cards.length }} {{ cards.length === 1 ? 'card' : 'cards' }}
      </span>
    </div>

    <!-- Buttons -->
    <div v-else-if="isButtons" class="flex flex-col gap-3">
      <FormattedContent v-if="bodyText" :content="bodyText" />
      <InteractiveButtons :buttons="buttons" />
    </div>

    <!-- List -->
    <div v-else-if="isList" class="flex flex-col gap-3">
      <FormattedContent v-if="bodyText" :content="bodyText" />
      <InteractiveButtons :buttons="buttons" is-list />
    </div>

    <!-- Fallback -->
    <div v-else>
      <FormattedContent v-if="content" :content="content" />
    </div>
  </BaseBubble>
</template>
