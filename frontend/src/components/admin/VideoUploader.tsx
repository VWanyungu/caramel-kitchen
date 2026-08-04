import { useRef, useState } from 'react'
import { uploadRecipeVideo } from '../../lib/adminRecipesApi'
import { extractErrorMessage } from '../../lib/api'
import './video-uploader.css'

type UploadState = 'idle' | 'uploading' | 'processing' | 'error'

interface VideoUploaderProps {
  onUploaded: (videoKey: string | null) => void
}

export default function VideoUploader({ onUploaded }: VideoUploaderProps) {
  const [state, setState] = useState<UploadState>('idle')
  const [fileName, setFileName] = useState<string | null>(null)
  const [progress, setProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  async function handleFile(file: File) {
    setFileName(file.name)
    setState('uploading')
    setProgress(0)
    setError(null)
    try {
      const { videoKey } = await uploadRecipeVideo(file, setProgress)
      setState('processing')
      onUploaded(videoKey)
    } catch (err) {
      setState('error')
      setError(extractErrorMessage(err, 'Could not upload this video.'))
    }
  }

  return (
    <div className="field">
      <label className="field-label" htmlFor="recipe-video-input">
        Recipe video
      </label>
      <div className="video-uploader">
        <input
          id="recipe-video-input"
          ref={inputRef}
          type="file"
          accept="video/mp4,video/quicktime,video/webm,video/mpeg"
          onChange={(event) => {
            const file = event.target.files?.[0]
            if (file) handleFile(file)
          }}
        />
        {state === 'idle' && (
          <p className="video-uploader-hint">MP4, MOV, WebM, or MPEG — up to 500MB.</p>
        )}
        {state === 'uploading' && (
          <div className="video-uploader-progress">
            <div className="video-uploader-bar">
              <div className="video-uploader-bar-fill" style={{ width: `${progress}%` }} />
            </div>
            <span>Uploading {fileName} — {progress}%</span>
          </div>
        )}
        {state === 'processing' && (
          <p className="video-uploader-hint video-uploader-hint-ok">
            {fileName} uploaded — it will finish processing shortly.
          </p>
        )}
        {state === 'error' && (
          <p className="field-error" role="alert">
            {error}
          </p>
        )}
      </div>
    </div>
  )
}
