<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ProductPicker from './ProductPicker.vue';
import CarouselAPI from 'dashboard/api/carousel';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  accountId: {
    type: Number,
    required: true,
  },
  conversationId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close', 'sent', 'update:show']);

const { t } = useI18n();

const selectedProducts = ref([]);
const carouselText = ref('');
const isSending = ref(false);

const localShow = computed({
  get: () => props.show,
  set: value => emit('update:show', value),
});

const canSend = computed(
  () => selectedProducts.value.length > 0 && !isSending.value
);

const modalSubtitle = computed(() => {
  const count = selectedProducts.value.length;
  if (count === 0) return t('PRODUCT_CAROUSEL.MODAL.SUBTITLE_EMPTY');
  return t('PRODUCT_CAROUSEL.MODAL.SUBTITLE_SELECTED', { count });
});

const closeModal = () => {
  selectedProducts.value = [];
  carouselText.value = '';
  emit('close');
};

const sendCarousel = async () => {
  if (!canSend.value) return;

  isSending.value = true;
  try {
    const productIds = selectedProducts.value.map(p => p.id);
    await CarouselAPI.sendCarousel(props.accountId, props.conversationId, {
      productIds,
      text: carouselText.value || undefined,
    });

    useAlert(t('PRODUCT_CAROUSEL.SEND_SUCCESS'));
    emit('sent');
    closeModal();
  } catch {
    useAlert(t('PRODUCT_CAROUSEL.SEND_ERROR'));
  } finally {
    isSending.value = false;
  }
};
</script>

<template>
  <woot-modal v-model:show="localShow" :on-close="closeModal" size="modal-big">
    <woot-modal-header
      :header-title="t('PRODUCT_CAROUSEL.MODAL.TITLE')"
      :header-content="modalSubtitle"
    />
    <div class="px-8 py-6">
      <ProductPicker
        v-model:selected-products="selectedProducts"
        v-model:text="carouselText"
      />

      <div class="flex gap-2 mt-6">
        <Button
          :label="t('PRODUCT_CAROUSEL.BUTTON_CANCEL')"
          color="slate"
          variant="faded"
          @click="closeModal"
        />
        <Button
          :label="t('PRODUCT_CAROUSEL.BUTTON_SEND')"
          :disabled="!canSend"
          :is-loading="isSending"
          @click="sendCarousel"
        />
      </div>
    </div>
  </woot-modal>
</template>
