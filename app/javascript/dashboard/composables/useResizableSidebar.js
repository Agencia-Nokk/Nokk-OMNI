import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useUISettings } from './useUISettings';
import { useWindowSize } from '@vueuse/core';
import wootConstants from 'dashboard/constants/globals';

const DEFAULT_WIDTH = 320;
const MIN_WIDTH = 200;
const MAX_WIDTH = 600;

export function useResizableSidebar(sidebarKey, defaultWidth = DEFAULT_WIDTH) {
  const { uiSettings, updateUISettings } = useUISettings();
  const { width: windowWidth } = useWindowSize();
  const isResizing = ref(false);
  const startX = ref(0);
  const startWidth = ref(0);

  const isSmallScreen = computed(
    () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
  );

  const savedWidth = computed(() => {
    const key = `sidebar_${sidebarKey}_width`;
    return uiSettings.value?.[key] || defaultWidth;
  });

  const sidebarWidth = ref(savedWidth.value);

  const updateWidth = newWidth => {
    const clampedWidth = Math.max(MIN_WIDTH, Math.min(MAX_WIDTH, newWidth));
    sidebarWidth.value = clampedWidth;
    updateUISettings({
      [`sidebar_${sidebarKey}_width`]: clampedWidth,
    });
  };

  const handleMouseDown = e => {
    if (isSmallScreen.value) return;
    isResizing.value = true;
    startX.value = e.clientX;
    startWidth.value = sidebarWidth.value;
    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
    e.preventDefault();
    e.stopPropagation();
  };

  const handleMouseMove = e => {
    if (!isResizing.value) return;

    const diff = e.clientX - startX.value;
    const isRTL = document.documentElement.dir === 'rtl';
    const newWidth =
      sidebarKey === 'left'
        ? isRTL
          ? startWidth.value - diff
          : startWidth.value + diff
        : isRTL
          ? startWidth.value + diff
          : startWidth.value - diff;

    updateWidth(newWidth);
  };

  const handleMouseUp = () => {
    isResizing.value = false;
    document.removeEventListener('mousemove', handleMouseMove);
    document.removeEventListener('mouseup', handleMouseUp);
    document.body.style.cursor = '';
    document.body.style.userSelect = '';
  };

  const resetWidth = () => {
    updateWidth(defaultWidth);
  };

  onMounted(() => {
    sidebarWidth.value = savedWidth.value;
  });

  onUnmounted(() => {
    document.removeEventListener('mousemove', handleMouseMove);
    document.removeEventListener('mouseup', handleMouseUp);
  });

  const widthStyle = computed(() => {
    if (isSmallScreen.value) {
      return {};
    }
    return {
      width: `${sidebarWidth.value}px`,
      minWidth: `${sidebarWidth.value}px`,
      maxWidth: `${sidebarWidth.value}px`,
    };
  });

  const resizeHandleClass = computed(() => {
    const baseClass =
      'hidden md:block absolute top-0 bottom-0 w-1 cursor-col-resize z-50 hover:bg-n-blue-11 transition-colors';
    return sidebarKey === 'left'
      ? `ltr:right-0 rtl:left-0 ${baseClass}`
      : `ltr:left-0 rtl:right-0 ${baseClass}`;
  });

  return {
    sidebarWidth,
    widthStyle,
    resizeHandleClass,
    handleMouseDown,
    resetWidth,
    isResizing,
  };
}
