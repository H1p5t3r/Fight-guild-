export const MAX_SEQUENCE_STEPS=12;
export const MAX_SEQUENCE_DELAY=120;
export function validateSequence(queue,moveCount=45){
 if(!Array.isArray(queue)||queue.length>MAX_SEQUENCE_STEPS)throw new Error(`Use up to ${MAX_SEQUENCE_STEPS} moves in a sequence.`);
 for(const step of queue){
  if(!step||typeof step!=='object'||!Number.isInteger(step.move)||step.move<0||step.move>=moveCount)throw new Error('A sequence contains an unknown move.');
  if(!Number.isInteger(step.delay)||step.delay<0||step.delay>MAX_SEQUENCE_DELAY)throw new Error(`Sequence delays must be whole frames from 0 to ${MAX_SEQUENCE_DELAY}.`);
 }
 return queue;
}
