<script setup>
import { computed } from 'vue';
import { messageStamp } from 'shared/helpers/timeHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import ToggleSwitch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  automation: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle', 'delete', 'clone']);

const readableDate = date => messageStamp(new Date(date), 'LLL d, yyyy');
const readableDateWithTime = date =>
  messageStamp(new Date(date), 'LLL d, yyyy hh:mm a');

const automationActive = computed({
  get: () => props.automation.active,
  set: active => {
    const { id, name } = props.automation;
    emit('toggle', {
      id,
      name,
      status: !active,
    });
  },
});
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4 min-w-[200px]">
      <router-link
        :to="{
          name: 'automation_edit',
          params: { automationId: automation.id },
        }"
        class="text-left hover:text-n-brand cursor-pointer hover:underline"
      >
        {{ automation.name }}
      </router-link>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">{{ automation.description }}</td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <ToggleSwitch v-model="automationActive" />
    </td>
    <td
      class="py-4 ltr:pr-4 rtl:pl-4 min-w-[12px]"
      :title="readableDateWithTime(automation.created_on)"
    >
      {{ readableDate(automation.created_on) }}
    </td>
    <td class="py-4 min-w-xs">
      <div class="flex gap-1 justify-end flex-shrink-0">
        <router-link
          :to="{
            name: 'automation_edit',
            params: { automationId: automation.id },
          }"
        >
          <Button
            v-tooltip.top="$t('AUTOMATION.FORM.EDIT')"
            icon="i-lucide-pen"
            slate
            xs
            faded
            :is-loading="loading"
          />
        </router-link>
        <Button
          v-tooltip.top="$t('AUTOMATION.CLONE.TOOLTIP')"
          icon="i-lucide-copy-plus"
          xs
          faded
          :is-loading="loading"
          @click="$emit('clone', automation)"
        />
        <Button
          v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
          :is-loading="loading"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          @click="$emit('delete', automation)"
        />
      </div>
    </td>
  </tr>
</template>
