import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import {
  automationToFlow,
  flowToAutomation,
} from './useAutomationFlowConverter';

const HORIZONTAL_SPACING = 250;
const VERTICAL_SPACING = 120;
const START_X = 100;
const START_Y = 200;

export function useAutomationFlow(automation, onUpdate) {
  const { t } = useI18n();

  const nodes = ref([]);
  const edges = ref([]);
  const selectedNode = ref(null);

  // Converter automação inicial para flow
  const initializeFlow = () => {
    if (automation.value) {
      const flowData = automationToFlow(automation.value);
      nodes.value = flowData.nodes;
      edges.value = flowData.edges;
    }
  };

  // Sincronizar mudanças do flow de volta para automação
  const syncToAutomation = () => {
    if (nodes.value.length > 0 && edges.value.length > 0) {
      const updatedAutomation = flowToAutomation(nodes.value, edges.value);
      // Preservar campos que não estão no flow (name, description, active)
      automation.value = {
        ...automation.value,
        ...updatedAutomation,
      };
      if (onUpdate) {
        onUpdate(automation.value);
      }
    }
  };

  // Adicionar novo nó
  // autoConnect: se true, conecta automaticamente ao último nó (usado no Quick Add)
  // se false, apenas adiciona o nó sem conectar (usado no drag-and-drop)
  const addNode = (nodeType, position = null, autoConnect = true) => {
    const nodeId = `${nodeType}-${Date.now()}`;
    const existingNodes = nodes.value;

    // Calcular posição se não fornecida
    let nodePosition = position;
    if (!nodePosition) {
      // Encontrar nós do mesmo tipo para calcular Y
      const sameTypeNodes = existingNodes.filter(n => n.type === nodeType);
      // Encontrar a posição X máxima de todos os nós
      const maxX = existingNodes.reduce(
        (max, n) => Math.max(max, n.position.x),
        START_X - HORIZONTAL_SPACING
      );
      // Calcular Y baseado em quantos nós do mesmo tipo existem
      const baseY = START_Y + sameTypeNodes.length * VERTICAL_SPACING;

      if (existingNodes.length > 0) {
        nodePosition = {
          x: maxX + HORIZONTAL_SPACING,
          y: baseY,
        };
      } else {
        nodePosition = { x: START_X, y: START_Y };
      }
    }

    let nodeData = {};
    if (nodeType === 'trigger') {
      nodeData = {
        event_name: 'conversation_created',
      };
    } else if (nodeType === 'condition') {
      nodeData = {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: '',
        query_operator: 'and',
        custom_attribute_type: '',
      };
    } else if (nodeType === 'action') {
      nodeData = {
        action_name: 'assign_agent',
        action_params: [],
      };
    }

    const newNode = {
      id: nodeId,
      type: nodeType,
      position: nodePosition,
      draggable: true,
      data: {
        ...nodeData,
        label: nodeType,
      },
    };

    nodes.value = [...nodes.value, newNode];

    // Conectar automaticamente se houver nós anteriores E autoConnect for true
    if (autoConnect && existingNodes.length > 0) {
      const lastNode = existingNodes[existingNodes.length - 1];
      const newEdge = {
        id: `edge-${lastNode.id}-${nodeId}`,
        source: lastNode.id,
        target: nodeId,
        type: 'smoothstep',
        animated: true,
      };

      edges.value = [...edges.value, newEdge];
    }

    syncToAutomation();
    return newNode;
  };

  // Remover nó
  const removeNode = nodeId => {
    // Não permitir remover o trigger
    const node = nodes.value.find(n => n.id === nodeId);
    if (node && node.type === 'trigger') {
      useAlert(t('AUTOMATION.FLOW.CANNOT_REMOVE_TRIGGER'));
      return;
    }

    // Remover edges conectadas
    edges.value = edges.value.filter(
      edge => edge.source !== nodeId && edge.target !== nodeId
    );

    // Remover nó
    nodes.value = nodes.value.filter(n => n.id !== nodeId);

    syncToAutomation();
  };

  // Atualizar dados de um nó
  const updateNodeData = (nodeId, updatedData) => {
    const updatedNodes = nodes.value.map(node => {
      if (node.id === nodeId) {
        return {
          ...node,
          data: {
            ...node.data,
            ...updatedData,
          },
        };
      }
      return node;
    });

    nodes.value = updatedNodes;
    syncToAutomation();
  };

  // Selecionar nó
  const selectNode = node => {
    selectedNode.value = node;
  };

  // Deselecionar nó
  const deselectNode = () => {
    selectedNode.value = null;
  };

  // Validar conexão
  const isValidConnection = connection => {
    const sourceNode = nodes.value.find(n => n.id === connection.source);
    const targetNode = nodes.value.find(n => n.id === connection.target);

    if (!sourceNode || !targetNode) return false;

    // Trigger só pode conectar a condições
    if (sourceNode.type === 'trigger' && targetNode.type !== 'condition') {
      return false;
    }

    // Condições podem conectar a outras condições ou ações
    if (sourceNode.type === 'condition') {
      return targetNode.type === 'condition' || targetNode.type === 'action';
    }

    // Ações podem conectar a outras ações
    if (sourceNode.type === 'action') {
      return targetNode.type === 'action';
    }

    return false;
  };

  return {
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
  };
}
