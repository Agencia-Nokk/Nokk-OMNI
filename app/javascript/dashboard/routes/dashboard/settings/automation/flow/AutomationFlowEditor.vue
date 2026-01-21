<script setup>
import { ref, onMounted, onUnmounted, watch, markRaw, provide } from 'vue';
import { VueFlow } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import TriggerNode from './nodes/TriggerNode.vue';
import ConditionNode from './nodes/ConditionNode.vue';
import ActionNode from './nodes/ActionNode.vue';
import NodeConfigPanel from './panels/NodeConfigPanel.vue';
import NodePalette from './panels/NodePalette.vue';
import { useAutomationFlow } from './composables/useAutomationFlow';
import '@vue-flow/core/dist/style.css';
import '@vue-flow/core/dist/theme-default.css';

const props = defineProps({
  automationData: {
    type: Object,
    required: true,
  },
  automationTypes: {
    type: Object,
    required: true,
  },
  automationActionTypes: {
    type: Array,
    default: () => [],
  },
  allCustomAttributes: {
    type: Array,
    default: () => [],
  },
  getConditionDropdownValues: {
    type: Function,
    required: true,
  },
  getActionDropdownValues: {
    type: Function,
    required: true,
  },
});

const emit = defineEmits(['update:automationData']);

const { t } = useI18n();

const automation = ref(props.automationData);
const showConfigPanel = ref(false);
const isInternalUpdate = ref(false);

// Definir tipos de nós customizados
const nodeTypes = {
  trigger: markRaw(TriggerNode),
  condition: markRaw(ConditionNode),
  action: markRaw(ActionNode),
};

// Inicializar flow
const {
  nodes,
  edges,
  selectedNode,
  initializeFlow,
  syncToAutomation,
  addNode,
  removeNode,
  updateNodeData,
  selectNode,
  deselectNode,
  isValidConnection,
} = useAutomationFlow(automation, updatedAutomation => {
  isInternalUpdate.value = true;
  emit('update:automationData', updatedAutomation);
});

// Watch para sincronizar quando props mudam externamente
watch(
  () => props.automationData,
  newData => {
    if (isInternalUpdate.value) {
      isInternalUpdate.value = false;
      return;
    }
    automation.value = newData;
    initializeFlow();
  },
  { deep: true }
);

// Handlers do VueFlow serão definidos dentro do template usando eventos do VueFlow
const handleNodesChange = changes => {
  // Processar apenas remoções - o VueFlow já cuida do drag automaticamente com v-model
  changes.forEach(change => {
    if (change.type === 'remove') {
      removeNode(change.id);
    }
  });
};

const handleEdgesChange = () => {
  syncToAutomation();
};

// Handler para quando o drag de um nó termina
const handleNodeDragStop = () => {
  syncToAutomation();
};

const handleConnect = connection => {
  if (isValidConnection(connection)) {
    // Adicionar nova edge
    const newEdge = {
      id: `edge-${connection.source}-${connection.target}`,
      source: connection.source,
      target: connection.target,
      type: 'smoothstep',
      animated: true,
    };
    edges.value = [...edges.value, newEdge];
    syncToAutomation();
  } else {
    // Reverter conexão inválida
    useAlert(t('AUTOMATION.FLOW.INVALID_CONNECTION'));
  }
};

// Handler para clique em nó
const handleNodeClick = event => {
  const node = event.node || event;
  selectNode(node);
  showConfigPanel.value = true;
};

// Handler para atualizar nó
const handleUpdateNode = updatedNode => {
  if (updatedNode && updatedNode.id) {
    updateNodeData(updatedNode.id, updatedNode.data);
    // Atualizar selectedNode também
    if (selectedNode.value && selectedNode.value.id === updatedNode.id) {
      selectedNode.value = {
        ...selectedNode.value,
        data: { ...selectedNode.value.data, ...updatedNode.data },
      };
    }
    syncToAutomation();
  }
};

// Handler para adicionar nó da paleta (Quick Add - conecta automaticamente)
const handleAddNode = nodeConfig => {
  const newNode = addNode(nodeConfig.type, null, true); // autoConnect = true
  selectNode(newNode);
  showConfigPanel.value = true;
};

// Handler para drag and drop (não conecta automaticamente)
const handleDrop = event => {
  event.preventDefault();
  const data = event.dataTransfer.getData('application/vueflow');
  if (data) {
    try {
      const nodeConfig = JSON.parse(data);
      const rect = event.currentTarget.getBoundingClientRect();
      const position = {
        x: event.clientX - rect.left,
        y: event.clientY - rect.top,
      };
      const newNode = addNode(nodeConfig.type, position, false); // autoConnect = false
      selectNode(newNode);
      showConfigPanel.value = true;
    } catch {
      // Invalid node data, ignore
    }
  }
};

const handleDragOver = event => {
  event.preventDefault();
};

// Handler para deletar nó selecionado
const handleDeleteSelectedNode = () => {
  if (selectedNode.value && selectedNode.value.type !== 'trigger') {
    removeNode(selectedNode.value.id);
    showConfigPanel.value = false;
    deselectNode();
  } else if (selectedNode.value && selectedNode.value.type === 'trigger') {
    useAlert(t('AUTOMATION.FLOW.CANNOT_REMOVE_TRIGGER'));
  }
};

// Handler para deletar nó pelo ID (usado pelo botão de delete no nó)
const handleDeleteNode = nodeId => {
  const node = nodes.value.find(n => n.id === nodeId);
  if (node && node.type !== 'trigger') {
    removeNode(nodeId);
    if (selectedNode.value && selectedNode.value.id === nodeId) {
      showConfigPanel.value = false;
      deselectNode();
    }
  } else if (node && node.type === 'trigger') {
    useAlert(t('AUTOMATION.FLOW.CANNOT_REMOVE_TRIGGER'));
  }
};

// Provide a função de delete para os nós
provide('deleteNode', handleDeleteNode);

// Handler para teclas (Delete/Backspace)
const handleKeyDown = event => {
  if (
    (event.key === 'Delete' || event.key === 'Backspace') &&
    selectedNode.value
  ) {
    // Não deletar se estiver focado em um input
    if (
      event.target.tagName === 'INPUT' ||
      event.target.tagName === 'TEXTAREA' ||
      event.target.tagName === 'SELECT'
    ) {
      return;
    }
    event.preventDefault();
    handleDeleteSelectedNode();
  }
};

// Ajustar visualização ao montar
onMounted(() => {
  initializeFlow();
  document.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeyDown);
});
</script>

<template>
  <div class="flex w-full h-full bg-n-slate-1 dark:bg-n-solid-1">
    <!-- Sidebar esquerdo - Paleta de nós -->
    <NodePalette
      :event-name="automation.event_name"
      @add-node="handleAddNode"
    />

    <!-- Painel de configuração - ao lado da paleta -->
    <NodeConfigPanel
      v-if="showConfigPanel && selectedNode"
      :selected-node="selectedNode"
      :automation-types="automationTypes"
      :automation-action-types="automationActionTypes"
      :all-custom-attributes="allCustomAttributes"
      :event-name="automation.event_name"
      :get-condition-dropdown-values="getConditionDropdownValues"
      :get-action-dropdown-values="getActionDropdownValues"
      @update:node="handleUpdateNode"
      @close="showConfigPanel = false"
    />

    <!-- Canvas -->
    <div class="flex-1 h-full" @drop="handleDrop" @dragover="handleDragOver">
      <VueFlow
        v-model:nodes="nodes"
        v-model:edges="edges"
        :node-types="nodeTypes"
        :default-edge-options="{ type: 'smoothstep', animated: true }"
        fit-view-on-init
        :min-zoom="0.2"
        :max-zoom="2"
        nodes-draggable
        nodes-connectable
        elements-selectable
        class="w-full h-full"
        @nodes-change="handleNodesChange"
        @edges-change="handleEdgesChange"
        @connect="handleConnect"
        @node-click="handleNodeClick"
        @node-drag-stop="handleNodeDragStop"
        @pane-click="deselectNode"
      >
        <Background pattern-color="#e5e7eb" :gap="16" />
        <Controls
          class="bg-n-slate-1 dark:bg-n-solid-2 border border-n-strong rounded-lg shadow-lg"
        />
        <MiniMap
          class="bg-n-slate-1 dark:bg-n-solid-2 border border-n-strong rounded-lg shadow-lg"
          pannable
          zoomable
          :node-color="
            node => {
              if (node.type === 'trigger') return '#14b8a6';
              if (node.type === 'condition') return '#eab308';
              return '#3b82f6';
            }
          "
        />
      </VueFlow>
    </div>
  </div>
</template>
