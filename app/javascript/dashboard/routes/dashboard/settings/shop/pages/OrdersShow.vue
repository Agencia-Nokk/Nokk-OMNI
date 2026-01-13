<script setup>
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Spinner from 'shared/components/Spinner.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const order = ref(null);
const internalNotes = ref('');
const uiFlags = ref({
  isFetching: false,
  isUpdating: false,
});

const fetchOrder = async () => {
  uiFlags.value.isFetching = true;
  try {
    const response = await ShopAPI.getOrder(route.params.orderId);
    order.value = response.data;
    internalNotes.value = order.value.internal_notes || '';
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetching = false;
  }
};

onMounted(() => {
  fetchOrder();
});

const goBack = () => {
  router.push({ name: 'shop_orders' });
};

const goToConversation = () => {
  router.push({
    name: 'inbox_conversation',
    params: { conversation_id: order.value.conversation.id },
  });
};

const getProductImage = item => {
  if (item.product?.primary_image?.url) {
    return item.product.primary_image.url;
  }
  return null;
};

const saveNotes = async () => {
  if (internalNotes.value === order.value.internal_notes) return;

  try {
    await ShopAPI.updateOrder(order.value.id, {
      internal_notes: internalNotes.value,
    });
    order.value.internal_notes = internalNotes.value;
  } catch (error) {
    useAlert(error.message);
  }
};

const confirmOrder = async () => {
  uiFlags.value.isUpdating = true;
  try {
    const response = await ShopAPI.confirmOrder(order.value.id);
    order.value = response.data;
    useAlert('Pedido confirmado com sucesso!');
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isUpdating = false;
  }
};

const cancelOrder = async () => {
  // eslint-disable-next-line no-alert, no-restricted-globals
  if (
    !window.confirm(
      t('SHOP.ORDERS.DETAILS.CONFIRM_ACTION', { action: 'cancelar' })
    )
  )
    return;

  uiFlags.value.isUpdating = true;
  try {
    const response = await ShopAPI.cancelOrder(order.value.id);
    order.value = response.data;
    useAlert('Pedido cancelado.');
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isUpdating = false;
  }
};

const getStatusClass = status => {
  const classes = {
    pending:
      'bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200',
    confirmed: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    processing:
      'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
    shipped:
      'bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200',
    delivered:
      'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
    cancelled: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
  };
  return classes[status] || 'bg-slate-100 text-slate-800';
};

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};

const formatDate = date => {
  if (!date) return '';
  return new Date(date).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};
</script>

<template>
  <div class="flex flex-col h-full">
    <!-- Header -->
    <div
      class="flex items-center justify-between p-4 border-b border-slate-75 dark:border-slate-800"
    >
      <div class="flex items-center gap-3">
        <button
          class="p-2 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
          @click="goBack"
        >
          <div class="i-lucide-arrow-left size-5 text-slate-600" />
        </button>
        <div>
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
            {{
              $t('SHOP.ORDERS.DETAILS.ORDER_NUMBER', {
                number: order?.order_number,
              })
            }}
          </h2>
          <p class="text-sm text-slate-600 dark:text-slate-400">
            {{ formatDate(order?.created_at) }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <span
          class="inline-flex px-3 py-1 text-sm font-medium rounded-full"
          :class="getStatusClass(order?.status)"
        >
          {{ $t(`SHOP.ORDERS.STATUS.${order?.status?.toUpperCase()}`) }}
        </span>
      </div>
    </div>

    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center h-full"
    >
      <Spinner />
    </div>

    <div v-else-if="order" class="flex-1 overflow-auto p-6">
      <div class="max-w-4xl mx-auto space-y-6">
        <!-- Customer & Conversation Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Customer Card -->
          <div
            class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-4"
          >
            <h3
              class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-3"
            >
              {{ $t('SHOP.ORDERS.DETAILS.CUSTOMER') }}
            </h3>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <div class="i-lucide-user size-4 text-slate-400" />
                <span class="text-sm text-slate-900 dark:text-slate-100">
                  {{ order.contact?.name }}
                </span>
              </div>
              <div v-if="order.contact?.email" class="flex items-center gap-2">
                <div class="i-lucide-mail size-4 text-slate-400" />
                <span class="text-sm text-slate-600 dark:text-slate-400">
                  {{ order.contact.email }}
                </span>
              </div>
              <div
                v-if="order.contact?.phone_number"
                class="flex items-center gap-2"
              >
                <div class="i-lucide-phone size-4 text-slate-400" />
                <span class="text-sm text-slate-600 dark:text-slate-400">
                  {{ order.contact.phone_number }}
                </span>
              </div>
            </div>
          </div>

          <!-- Conversation Card -->
          <div
            class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-4"
          >
            <h3
              class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-3"
            >
              {{ $t('SHOP.ORDERS.DETAILS.CONVERSATION') }}
            </h3>
            <div class="space-y-2">
              <div class="flex items-center gap-2">
                <div class="i-lucide-message-square size-4 text-slate-400" />
                <span class="text-sm text-slate-900 dark:text-slate-100">
                  {{
                    $t('SHOP.ORDERS.DETAILS.CONVERSATION_NUMBER', {
                      number: order.conversation?.display_id,
                    })
                  }}
                </span>
              </div>
              <div v-if="order.user" class="flex items-center gap-2">
                <div class="i-lucide-headphones size-4 text-slate-400" />
                <span class="text-sm text-slate-600 dark:text-slate-400">
                  {{
                    $t('SHOP.ORDERS.DETAILS.AGENT', { name: order.user.name })
                  }}
                </span>
              </div>
              <button
                v-if="order.conversation?.id"
                class="mt-2 text-sm text-woot-500 hover:text-woot-600 flex items-center gap-1"
                @click="goToConversation"
              >
                <div class="i-lucide-external-link size-4" />
                {{ $t('SHOP.ORDERS.DETAILS.GO_TO_CONVERSATION') }}
              </button>
            </div>
          </div>
        </div>

        <!-- Order Items -->
        <div
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div class="p-4 border-b border-slate-200 dark:border-slate-700">
            <h3 class="text-sm font-medium text-slate-700 dark:text-slate-300">
              {{
                $t('SHOP.ORDERS.DETAILS.ITEMS_TITLE', {
                  count: order.total_items,
                })
              }}
            </h3>
          </div>
          <div class="divide-y divide-slate-200 dark:divide-slate-700">
            <div
              v-for="item in order.items"
              :key="item.id"
              class="flex items-center gap-4 p-4"
            >
              <div
                class="w-16 h-16 bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden flex-shrink-0"
              >
                <img
                  v-if="getProductImage(item)"
                  :src="getProductImage(item)"
                  :alt="item.product_name"
                  class="w-full h-full object-cover"
                />
                <div
                  v-else
                  class="w-full h-full flex items-center justify-center"
                >
                  <div class="i-lucide-package size-8 text-slate-400" />
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <p
                  class="text-sm font-medium text-slate-900 dark:text-slate-100 truncate"
                >
                  {{ item.product_name }}
                </p>
                <p
                  v-if="item.variant_name"
                  class="text-xs text-slate-500 dark:text-slate-400"
                >
                  {{ item.variant_name }}
                </p>
                <p class="text-sm text-slate-600 dark:text-slate-400">
                  {{
                    $t('SHOP.ORDERS.DETAILS.QUANTITY', { count: item.quantity })
                  }}
                  {{ formatCurrency(item.unit_price) }}
                </p>
              </div>
              <div class="text-right">
                <p
                  class="text-sm font-medium text-slate-900 dark:text-slate-100"
                >
                  {{ formatCurrency(item.total_price) }}
                </p>
              </div>
            </div>
          </div>

          <!-- Order Summary -->
          <div
            class="p-4 bg-slate-50 dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700"
          >
            <div class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="text-slate-600 dark:text-slate-400">{{
                  $t('SHOP.ORDERS.DETAILS.SUBTOTAL')
                }}</span>
                <span class="text-slate-900 dark:text-slate-100">
                  {{ formatCurrency(order.subtotal) }}
                </span>
              </div>
              <div
                v-if="parseFloat(order.discount) > 0"
                class="flex justify-between text-sm"
              >
                <span class="text-slate-600 dark:text-slate-400">{{
                  $t('SHOP.ORDERS.DETAILS.DISCOUNT')
                }}</span>
                <span class="text-green-600">
                  -{{ formatCurrency(order.discount) }}
                </span>
              </div>
              <div
                class="flex justify-between text-base font-semibold pt-2 border-t border-slate-200 dark:border-slate-700"
              >
                <span class="text-slate-900 dark:text-slate-100">{{
                  $t('SHOP.ORDERS.DETAILS.TOTAL')
                }}</span>
                <span class="text-slate-900 dark:text-slate-100">
                  {{ formatCurrency(order.total) }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Notes -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div
            class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-4"
          >
            <h3
              class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.ORDERS.DETAILS.CUSTOMER_NOTES') }}
            </h3>
            <p
              v-if="order.customer_notes"
              class="text-sm text-slate-600 dark:text-slate-400"
            >
              {{ order.customer_notes }}
            </p>
            <p v-else class="text-sm text-slate-400 italic">
              {{ $t('SHOP.ORDERS.DETAILS.NO_NOTES') }}
            </p>
          </div>

          <div
            class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-4"
          >
            <h3
              class="text-sm font-medium text-slate-700 dark:text-slate-300 mb-2"
            >
              {{ $t('SHOP.ORDERS.DETAILS.INTERNAL_NOTES') }}
            </h3>
            <textarea
              v-model="internalNotes"
              class="w-full p-2 text-sm border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-slate-100 resize-none"
              rows="3"
              placeholder="Adicionar notas internas..."
              @blur="saveNotes"
            />
          </div>
        </div>

        <!-- Actions -->
        <div
          class="flex items-center justify-end gap-3 pt-4 border-t border-slate-200 dark:border-slate-700"
        >
          <button
            v-if="order.status === 'pending'"
            class="px-4 py-2 text-sm font-medium text-white bg-green-600 hover:bg-green-700 rounded-lg flex items-center gap-2"
            :disabled="uiFlags.isUpdating"
            @click="confirmOrder"
          >
            <div class="i-lucide-check size-4" />
            {{ $t('SHOP.ORDERS.DETAILS.CONFIRM_ORDER') }}
          </button>
          <button
            v-if="order.status === 'pending' || order.status === 'confirmed'"
            class="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-lg flex items-center gap-2"
            :disabled="uiFlags.isUpdating"
            @click="cancelOrder"
          >
            <div class="i-lucide-x size-4" />
            {{ $t('SHOP.ORDERS.DETAILS.CANCEL_ORDER') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
