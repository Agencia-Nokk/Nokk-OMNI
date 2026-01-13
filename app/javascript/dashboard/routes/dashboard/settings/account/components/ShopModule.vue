<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const store = useStore();

const isUpdating = ref(false);

const shopSettings = computed(
  () => store.getters['shopSettings/getShopSettings']
);
const isEnabled = computed({
  get: () => shopSettings.value?.enabled || false,
  set: () => {},
});

onMounted(() => {
  store.dispatch('shopSettings/get');
});

const toggleShopModule = async () => {
  isUpdating.value = true;
  try {
    await store.dispatch('shopSettings/toggleEnabled');
    const newState = shopSettings.value?.enabled;
    if (newState) {
      useAlert(t('GENERAL_SETTINGS.FORM.SHOP_MODULE.API.ENABLED'));
    } else {
      useAlert(t('GENERAL_SETTINGS.FORM.SHOP_MODULE.API.DISABLED'));
    }
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.SHOP_MODULE.API.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.SHOP_MODULE.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.SHOP_MODULE.NOTE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch
          :model-value="isEnabled"
          :disabled="isUpdating"
          @change="toggleShopModule"
        />
      </div>
    </template>
    <div v-if="isEnabled" class="text-sm text-n-slate-11">
      {{ t('GENERAL_SETTINGS.FORM.SHOP_MODULE.ENABLED_HINT') }}
    </div>
    <div v-else class="text-sm text-n-slate-11">
      {{ t('GENERAL_SETTINGS.FORM.SHOP_MODULE.DISABLED_HINT') }}
    </div>
  </SectionLayout>
</template>
