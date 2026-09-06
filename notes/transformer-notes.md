# Attention Is All You Need - Summary & Notes

**Authors:** Vaswani et al. (Google Brain / Research)  
**Status:** Read & Summarized

## Core Contributions
- Proposes the **Transformer architecture**, dispensing with recurrence and convolutions entirely.
- Relies solely on **Multi-Head Self-Attention** mechanisms to draw global dependencies between input and output.
- Enables significantly more parallelization during training, drastically reducing training times.

## Key Mechanisms
1. **Scaled Dot-Product Attention:**
   $$\text{Attention}(Q, K, V) = \text{softmax}\left(\frac{QK^T}{\sqrt{d_k}}\right)V$$
2. **Positional Encoding:**
   Sinusoidal encodings added to input embeddings to retain sequential order.

## Mobile Notes & Action Items
- [x] Read primary paper
- [ ] Implement self-attention toy model in PyTorch
- [ ] Cross-reference with subsequent Sparse Attention papers
