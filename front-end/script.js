const chars =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()';

function scrambleText(element, finalText, duration = 1500) {
  let frame = 0;
  const maxFrames = duration / 30;

  const interval = setInterval(() => {
    let output = '';

    for (let i = 0; i < finalText.length; i++) {
      if (i < (frame / maxFrames) * finalText.length) {
        output += finalText[i];
      } else {
        output += chars[Math.floor(Math.random() * chars.length)];
      }
    }

    element.textContent = output;
    frame++;

    if (frame >= maxFrames) {
      clearInterval(interval);
      element.textContent = finalText;
    }
  }, 30);
}

document
  .querySelector('.shortener-form')
  .addEventListener('submit', async (e) => {
    e.preventDefault();

    const output = document.getElementById('output');

    // fake loading animation
    scrambleText(output, 'generating...', 1000);

    // simulate API delay
    setTimeout(() => {
      const fakeShort =
        'short.ly/' + Math.random().toString(36).substring(2, 8);
      scrambleText(output, fakeShort, 1500);
    }, 1200);
  });
