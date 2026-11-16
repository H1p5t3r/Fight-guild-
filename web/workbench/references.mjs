export const MAX_REFERENCES=3;
export const MAX_REFERENCE_DATA=700*1024;
export const MAX_REFERENCE_TOTAL=12*1024*1024;
export const MAX_IMPORT_BYTES=32*1024*1024;
export const REFERENCE_PHASES=[['general','General pose'],['windup','Windup'],['active','Active']];
const types=new Set(['image/png','image/jpeg','image/webp']);

export function validateReferences(references) {
  if(!Array.isArray(references)||references.length>MAX_REFERENCES)throw new Error('Use up to three pose references per move.');
  const ids=new Set();let size=0;
  for(const ref of references){
    if(!ref||typeof ref!=='object'||Array.isArray(ref)||typeof ref.id!=='string'||!/^[a-zA-Z0-9-]{1,64}$/.test(ref.id)||ids.has(ref.id))throw new Error('A pose reference has a missing or duplicate identifier.');
    ids.add(ref.id);
    if(!REFERENCE_PHASES.some(([value])=>value===ref.phase)||typeof ref.caption!=='string'||ref.caption.length>1000||typeof ref.name!=='string'||ref.name.length>160)throw new Error('A pose reference has invalid labels.');
    if(typeof ref.src!=='string'||ref.src.length>MAX_REFERENCE_DATA)throw new Error('A pose reference is too large. Add the photo through the workshop to resize it.');
    const match=/^data:(image\/(?:png|jpeg|webp));base64,([A-Za-z0-9+/]+={0,2})$/.exec(ref.src);
    if(!match||match[2].length%4)throw new Error('Pose references must be embedded JPG, PNG or WebP images.');
    const header=atob(match[2].slice(0,32));
    const valid=match[1]==='image/png'?header.startsWith('\x89PNG\r\n\x1a\n'):match[1]==='image/jpeg'?header.startsWith('\xff\xd8\xff'):header.startsWith('RIFF')&&header.slice(8,12)==='WEBP';
    if(!valid)throw new Error('A pose reference does not contain a supported image.');
    size+=ref.src.length;
  }
  return size;
}

// Prepare a portable copy locally. The user's source file is never changed or
// uploaded; removing EXIF metadata also avoids bundling camera/location data.
export async function prepareReference(file) {
  if(!types.has(file.type))throw new Error('Choose a JPG, PNG or WebP photo.');
  if(file.size>20*1024*1024)throw new Error('Choose a photo smaller than 20 MB.');
  const url=URL.createObjectURL(file),img=new Image();
  try {
    img.src=url;await img.decode();
    if(!img.naturalWidth||!img.naturalHeight)throw new Error('The photo could not be read.');
    const ratio=Math.min(1,1200/Math.max(img.naturalWidth,img.naturalHeight));
    const canvas=document.createElement('canvas');canvas.width=Math.max(1,Math.round(img.naturalWidth*ratio));canvas.height=Math.max(1,Math.round(img.naturalHeight*ratio));
    const context=canvas.getContext('2d');context.drawImage(img,0,0,canvas.width,canvas.height);
    let src='';for(const quality of [0.86,0.76,0.64,0.5]){src=canvas.toDataURL('image/webp',quality);if(src.length<=MAX_REFERENCE_DATA)break;}
    const id=Array.from(crypto.getRandomValues(new Uint32Array(4)),v=>v.toString(16).padStart(8,'0')).join('');
    const ref={id,phase:'general',caption:'',name:file.name.slice(0,160),src};validateReferences([ref]);return ref;
  } catch(error) {
    if(error.name==='EncodingError')throw new Error('The photo could not be read. Try a JPG, PNG or WebP copy.');
    throw error;
  } finally {URL.revokeObjectURL(url);}
}
