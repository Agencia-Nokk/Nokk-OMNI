<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['addNode', 'save', 'cancel']);

const addCondition = () => {
  emit('addNode', {
    type: 'condition',
    data: {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
      custom_attribute_type: '',
    },
  });
};

const addAction = () => {
  emit('addNode', {
    type: 'action',
    data: {
      action_name: 'assign_agent',
      action_params: [],
    },
  });
};
</script>

<template>
  <div
    class="h-full w-64 flex-shrink-0 bg-n-slate-1 dark:bg-n-solid-1 border-r border-n-strong overflow-y-auto flex flex-col"
  >
    <div class="p-4 flex flex-col flex-1">
      <h3 class="text-lg font-semibold text-n-slate-12 mb-4">
        {{ $t('AUTOMATION.FLOW.NODE_PALETTE') }}
      </h3>

      <div class="space-y-3">
        <div>
          <h4 class="text-sm font-medium text-n-slate-11 mb-2">
            {{ $t('AUTOMATION.FLOW.ADD_NODES') }}
          </h4>

          <div class="space-y-2">
            <!-- Trigger -->
            <div
              class="p-3 bg-n-teal-9 dark:bg-n-teal-10 rounded-lg border border-n-teal-10 cursor-move"
              draggable="true"
              @dragstart="
                $event.dataTransfer.setData(
                  'application/vueflow',
                  JSON.stringify({ type: 'trigger' })
                )
              "
            >
              <div class="flex items-center gap-2">
                <i class="ion-flash text-white" />
                <span class="text-sm font-medium text-white">
                  {{ $t('AUTOMATION.FLOW.TRIGGER') }}
                </span>
              </div>
              <p class="text-xs text-white opacity-80 mt-1">
                {{ $t('AUTOMATION.FLOW.DRAG_TO_ADD_TRIGGER') }}
              </p>
            </div>

            <!-- Condition -->
            <div
              class="p-3 bg-n-yellow-9 dark:bg-n-yellow-10 rounded-lg border border-n-yellow-10 cursor-move"
              draggable="true"
              @dragstart="
                $event.dataTransfer.setData(
                  'application/vueflow',
                  JSON.stringify({ type: 'condition' })
                )
              "
            >
              <div class="flex items-center gap-2">
                <i class="ion-funnel text-white" />
                <span class="text-sm font-medium text-white">
                  {{ $t('AUTOMATION.FLOW.CONDITION') }}
                </span>
              </div>
              <p class="text-xs text-white opacity-80 mt-1">
                {{ $t('AUTOMATION.FLOW.DRAG_TO_ADD_CONDITION') }}
              </p>
            </div>

            <!-- Action -->
            <div
              class="p-3 bg-n-blue-9 dark:bg-n-blue-10 rounded-lg border border-n-blue-10 cursor-move"
              draggable="true"
              @dragstart="
                $event.dataTransfer.setData(
                  'application/vueflow',
                  JSON.stringify({ type: 'action' })
                )
              "
            >
              <div class="flex items-center gap-2">
                <i class="ion-play text-white" />
                <span class="text-sm font-medium text-white">
                  {{ $t('AUTOMATION.FLOW.ACTION') }}
                </span>
              </div>
              <p class="text-xs text-white opacity-80 mt-1">
                {{ $t('AUTOMATION.FLOW.DRAG_TO_ADD_ACTION') }}
              </p>
            </div>
          </div>
        </div>

        <div class="pt-4 border-t border-n-strong">
          <h4 class="text-sm font-medium text-n-slate-11 mb-2">
            {{ $t('AUTOMATION.FLOW.QUICK_ADD') }}
          </h4>

          <div class="space-y-2">
            <Button
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
              @click="addCondition"
            />
            <Button
              icon="i-lucide-plus"
              blue
              faded
              sm
              :label="$t('AUTOMATION.ADD.ACTION_BUTTON_LABEL')"
              @click="addAction"
            />
          </div>
        </div>
      </div>

      <!-- Botões de Salvar/Cancelar -->
      <div class="mt-auto pt-4 border-t border-n-strong space-y-2">
        <Button
          icon="i-lucide-save"
          blue
          sm
          class="w-full"
          :label="$t('AUTOMATION.FORM.SAVE')"
          @click="emit('save')"
        />
        <Button
          icon="i-lucide-x"
          faded
          sm
          class="w-full"
          :label="$t('AUTOMATION.FORM.CANCEL')"
          @click="emit('cancel')"
        />
      </div>
    </div>
  </div>
</template>
