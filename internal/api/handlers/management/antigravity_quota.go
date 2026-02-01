package management

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	coreauth "github.com/router-for-me/CLIProxyAPI/v6/sdk/cliproxy/auth"
)

// GetAntigravityQuotas returns quota information for Antigravity auth files
func (h *Handler) GetAntigravityQuotas(c *gin.Context) {
	if h == nil || h.authManager == nil {
		c.JSON(http.StatusServiceUnavailable, gin.H{"error": "auth manager unavailable"})
		return
	}

	auths := h.authManager.List()

	result := make(map[string]interface{})

	// Find all Antigravity auth files
	for _, auth := range auths {
		if auth == nil || !strings.EqualFold(auth.Provider, "antigravity") {
			continue
		}

		// Skip disabled or unavailable auths
		if auth.Disabled || auth.Unavailable || auth.Status == coreauth.StatusDisabled {
			continue
		}

		// Create executor and fetch quotas
		// TODO: Re-enable GetQuotas after upstream merge is complete
		// exec := executor.NewAntigravityExecutor(h.cfg)
		// quotas, err := exec.GetQuotas(ctx, auth)
		// if err != nil {
		// 	log.WithError(err).Warnf("failed to get quotas for auth %s", auth.ID)
		// 	continue
		// }
		quotas := make(map[string]interface{}) // Temporary placeholder

		// Store quotas with auth file name as key
		fileName := auth.FileName
		if fileName == "" {
			fileName = auth.ID
		}
		result[fileName] = quotas
	}

	c.JSON(http.StatusOK, gin.H{"quotas": result})
}
