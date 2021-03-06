import Histogram from './Histogram';
import Heat from './Heat.js';
import Distance from './Distance';
import StackedBar from './StackedBar';
import Ratio from './Ratio';

export default function Measure(data,config,view,subglyph){
  switch (subglyph) {
    case 'histogram':
      return new Histogram(data,config,view);
    case 'heat':
      return new Heat(data,config,view);
    case 'distance':
      return new Distance(data,config,view);
    case 'stackedbar':
      return new StackedBar(data,config,view);
    case 'ratio':
      return new Ratio(data,config,view);
    default:
      console.log(`${subglyph} is not supported yet`);
  }
}