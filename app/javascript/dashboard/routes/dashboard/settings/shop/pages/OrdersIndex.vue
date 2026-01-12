<script setup>
import { ref, onMounted, onActivated } from 'vue';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import ShopAPI from 'dashboard/api/shop';
import Spinner from 'shared/components/Spinner.vue';

const router = useRouter();

const orders = ref([]);
const uiFlags = ref({
  isFetching: false,
});

const fetchOrders = async () => {
  // Only show loading if we don't have data yet
  if (!orders.value.length) {
    uiFlags.value.isFetching = true;
  }
  try {
    const response = await ShopAPI.getOrders();
    orders.value = response.data;
  } catch (error) {
    useAlert(error.message);
  } finally {
    uiFlags.value.isFetching = false;
  }
};

onMounted(() => {
  fetchOrders();
});

// Refetch when returning to this page (keep-alive)
onActivated(() => {
  fetchOrders();
});

const viewOrder = orderId => {
  router.push({ name: 'shop_orders_show', params: { orderId } });
};

const getStatusClass = status => {
  const classes = {
    pending: 'bg-amber-100 text-amber-800',
    confirmed: 'bg-blue-100 text-blue-800',
    processing: 'bg-purple-100 text-purple-800',
    shipped: 'bg-indigo-100 text-indigo-800',
    delivered: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
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
  return new Date(date).toLocaleDateString('pt-BR');
};
</script>

<template>
  <div class="flex flex-col h-full">
    <div class="p-4 border-b border-slate-75 dark:border-slate-800">
      <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-25">
        {{ $t('SHOP.ORDERS.TITLE') }}
      </h2>
      <p class="text-sm text-slate-600 dark:text-slate-400">
        {{ $t('SHOP.ORDERS.DESCRIPTION') }}
      </p>
    </div>

    <div
      v-if="uiFlags.isFetching"
      class="flex items-center justify-center h-full"
    >
      <Spinner />
    </div>

    <div
      v-else-if="!orders.length"
      class="flex flex-col items-center justify-center h-full p-8"
    >
      <div class="i-lucide-receipt text-6xl text-slate-400 mb-4" />
      <h3 class="text-lg font-medium text-slate-700 dark:text-slate-300 mb-2">
        {{ $t('SHOP.ORDERS.EMPTY_STATE.TITLE') }}
      </h3>
      <p
        class="text-sm text-slate-600 dark:text-slate-400 text-center max-w-md"
      >
        {{ $t('SHOP.ORDERS.EMPTY_STATE.MESSAGE') }}
      </p>
    </div>

    <div v-else class="flex-1 overflow-auto p-4">
      <div class="max-w-6xl mx-auto">
        <div
          class="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden"
        >
          <table class="w-full">
            <thead class="bg-slate-50 dark:bg-slate-800">
              <tr>
                <th
                  class="px-4 py-3 text-left text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.ORDERS.TABLE.ORDER') }}
                </th>
                <th
                  class="px-4 py-3 text-left text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.ORDERS.TABLE.CUSTOMER') }}
                </th>
                <th
                  class="px-4 py-3 text-left text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.ORDERS.TABLE.STATUS') }}
                </th>
                <th
                  class="px-4 py-3 text-left text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.ORDERS.TABLE.TOTAL') }}
                </th>
                <th
                  class="px-4 py-3 text-left text-xs font-medium text-slate-700 dark:text-slate-300"
                >
                  {{ $t('SHOP.ORDERS.TABLE.DATE') }}
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="order in orders"
                :key="order.id"
                class="border-t border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer"
                @click="viewOrder(order.id)"
              >
                <td
                  class="px-4 py-3 text-sm font-medium text-slate-900 dark:text-slate-100"
                >
                  #{{ order.order_number }}
                </td>
                <td
                  class="px-4 py-3 text-sm text-slate-600 dark:text-slate-400"
                >
                  {{ order.contact.name }}
                </td>
                <td class="px-4 py-3">
                  <span
                    class="inline-flex px-2 py-1 text-xs font-medium rounded"
                    :class="getStatusClass(order.status)"
                  >
                    {{ $t(`SHOP.ORDERS.STATUS.${order.status.toUpperCase()}`) }}
                  </span>
                </td>
                <td
                  class="px-4 py-3 text-sm font-medium text-slate-900 dark:text-slate-100"
                >
                  {{ formatCurrency(order.total) }}
                </td>
                <td
                  class="px-4 py-3 text-sm text-slate-600 dark:text-slate-400"
                >
                  {{ formatDate(order.created_at) }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
