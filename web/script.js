const POLL_INTERVAL_MS = 5000;
const MAX_POLL_ATTEMPTS = 60;

const form = document.getElementById("generate-form");
const promptInput = document.getElementById("prompt");
const charCount = document.getElementById("char-count");
const submitBtn = document.getElementById("submit-btn");
const statusPanel = document.getElementById("status-panel");
const statusMessage = document.getElementById("status-message");
const spinner = document.getElementById("spinner");
const errorPanel = document.getElementById("error-panel");
const videoPanel = document.getElementById("video-panel");
const resultVideo = document.getElementById("result-video");

promptInput.addEventListener("input", () => {
  charCount.textContent = `${promptInput.value.length} / 512`;
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  resetUi();

  const prompt = promptInput.value.trim();
  if (!prompt) {
    showError("Enter a prompt to generate a video.");
    return;
  }

  if (!window.APP_CONFIG?.apiBaseUrl) {
    showError("API URL is not configured. Redeploy the frontend after terraform apply.");
    return;
  }

  submitBtn.disabled = true;
  showStatus("Starting video generation...", true);

  try {
    const startResponse = await fetch(`${window.APP_CONFIG.apiBaseUrl}/jobs`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ prompt }),
    });

    const startPayload = await startResponse.json();
    if (!startResponse.ok) {
      throw new Error(startPayload.error || "Failed to start video generation.");
    }

    await pollJobStatus(startPayload.jobId);
  } catch (error) {
    showError(error.message || "Something went wrong.");
  } finally {
    submitBtn.disabled = false;
    spinner.classList.add("hidden");
  }
});

async function pollJobStatus(jobId) {
  for (let attempt = 0; attempt < MAX_POLL_ATTEMPTS; attempt += 1) {
    showStatus(`Generating video... (${attempt + 1}/${MAX_POLL_ATTEMPTS})`, true);

    const statusResponse = await fetch(`${window.APP_CONFIG.apiBaseUrl}/jobs/${jobId}`);
    const statusPayload = await statusResponse.json();

    if (!statusResponse.ok) {
      throw new Error(statusPayload.error || "Failed to fetch job status.");
    }

    if (statusPayload.status === "Completed") {
      showVideo(statusPayload.videoUrl);
      return;
    }

    if (statusPayload.status === "Failed") {
      throw new Error(statusPayload.failureMessage || "Video generation failed.");
    }

    await sleep(POLL_INTERVAL_MS);
  }

  throw new Error("Timed out waiting for the video. Try again in a few minutes.");
}

function resetUi() {
  errorPanel.classList.add("hidden");
  errorPanel.textContent = "";
  videoPanel.classList.add("hidden");
  resultVideo.removeAttribute("src");
  resultVideo.load();
}

function showStatus(message, showSpinner) {
  statusPanel.classList.remove("hidden");
  statusMessage.textContent = message;
  spinner.classList.toggle("hidden", !showSpinner);
}

function showError(message) {
  statusPanel.classList.add("hidden");
  errorPanel.textContent = message;
  errorPanel.classList.remove("hidden");
}

function showVideo(videoUrl) {
  statusPanel.classList.add("hidden");
  resultVideo.src = videoUrl;
  videoPanel.classList.remove("hidden");
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
